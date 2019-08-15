<html>

  <head>
    <title>USA Farmers Markets</title>
    <link rel="icon" href="https://img.icons8.com/officel/16/000000/organic-food.png"/>
    <style>
      input{width: 250px}
    </style>
  </head>

  <body>
    <h1 align="center">Search for farmers markets within a city, state, or zipcode!</h1>
    <p>
      You may enter <i>one or more</i> of the following search attributes:
    </p>
    <p>
      You may optionally enter a max radius to search between.
      This distance can only be applied to a city, market name,
      or zipcode. If you enter search parameters into multiple
      boxes, then we will find you markets that match ALL of those
      attributes. Happy searching!
    </p>
    <form method="GET">
      <table align="center">
        <tr>
          <td align="right">Market Name:</td>
          <td align="left"><input type="text" name="market" size="30"/></td>
        </tr>
        <tr>
          <td align="right">City:</td>
          <td align="left"><input type="text" name="city" size="30"/></td>
        </tr>
        <tr>
          <td align="right">State:</td>
          <td align="left"><input type="text" name="state" size="30"></td>
        </tr>
        <tr>
          <td align="right">Zipcode:</td>
          <td align="left"><input type="text" name="zipcode" size="30"></td>
        </tr>
        <tr>
          <td align="right">Range:</td>
          <td align="left"><input type="text" name="range" size="30"></td>
        </tr>
        <tr>
          <td align="right"></td>
          <td align="left"><input type="submit" value="Search"></td>
        </tr>
      </table>
    </form>

    <%@ page import="java.util.ArrayList, java.util.Map, java.util.HashMap, java.text.NumberFormat, java.text.DecimalFormat, java.io.IOException, java.sql.*" %>
    <%@ page import="java.io.BufferedReader, java.io.FileReader" %>

    <%!
    public int displayIndex = 0;
    public ArrayList<String[]> results = new ArrayList<String[]>();

    public class GetMarkets {

      private Connection conn = null;
      private Map<String, String> values;
      private final String[] params = {"market", "city", "state", "zipcode", "range"};


      /**
       *  Constructor for the class used to query the markets database.
       *  @param _values - a map of market attributes to user entered values
       */
      public GetMarkets(Map<String, String> _values) {
        this.values = _values;
      }


      /**
       *  Make a query to the database to retrieve markets based on
       *  user enetered value.
       *  @param None
       *  @return a ResultSet with the query results, return null if
       *          the query is invalid or an exception is thrown
       */
      public ResultSet makeQuery(JspWriter out) {
        String url = "jdbc:mysql://localhost:3306/farmers_markets";
        ResultSet rs = null;
        try {
          BufferedReader br;
          String username = null, password = null;
          try {
            br = new BufferedReader(new FileReader("./webapps/ROOT/credentials.txt"));
            String line = br.readLine();
            String[] info = line.split(":");
            username = info[0];
            password = info[1];
            br.close();
          } catch(Exception exception) {
            return null;
          }
          Class.forName("com.mysql.jdbc.Driver");
          conn = DriverManager.getConnection(url, username, password);

          // No range has been specified, so create the default query
          if (values.get("range") == null || values.get("range").equals("")) {
            String query = buildDefaultQuery();
            try  {
              PreparedStatement stat = conn.prepareStatement(query,
                                            ResultSet.TYPE_SCROLL_INSENSITIVE,
                                            ResultSet.CONCUR_UPDATABLE);
              int setter = 1;
              for (int i = 0; i < 3; i++) {
                String param = values.get(this.params[i]);
                if (param != null) {
                  stat.setString(setter++, param);
                }
              }
              String zip = values.get("zipcode");
              if (zip != null) {
                stat.setInt(setter, Integer.parseInt(zip));
              }
              rs = stat.executeQuery();
              return rs;
            } catch(Exception e) {
              System.err.println("ERROR: <unable to make default query>");
              return null;
            }
          } else {
            // Find the nearest market based on the users input
            String query = buildRangeQuery();
            if (query == null)
              return null;
            double lat = 0;
            double lon = 0;
            try (PreparedStatement stat = conn.prepareStatement(query)) {
              int setter = 1;
              if (values.get("market") != null)  stat.setString(setter++, values.get("market"));
              if (values.get("city") != null)    stat.setString(setter++, values.get("city"));
              if (values.get("zipcode") != null) stat.setInt(setter++, Integer.parseInt(values.get("zipcode")));
              rs = stat.executeQuery();

              // Retrieve the latitude and longitude
              while (lat == 0 && lon == 0 && rs.next()) {
                lat = rs.getDouble("latitude");
                lon = rs.getDouble("longitude");
              }
              if (lat == 0 && lon == 0) { // Call failed
                return null;
              } else { // Add minor amount in order to get the query market included
                lat += .0000001;
                lon += .0000001;
              }
            } catch(Exception e) {
              System.err.println("ERROR: <unable to build range query>");
              out.println("<p>"+e.toString()+"</p>");
              return null;
            }

            // Set latitude and longitude values
            String setStatement = "SET @lat=?, @long=?;";
            PreparedStatement stat = conn.prepareStatement(setStatement);
            stat.setDouble(1, lat);
            stat.setDouble(2, lon);
            stat.execute();

            // Query for all markets within the range
            String distanceQuery = buildDistanceQuery();
            try {
              stat = conn.prepareStatement(distanceQuery,
                                           ResultSet.TYPE_SCROLL_INSENSITIVE,
                                           ResultSet.CONCUR_UPDATABLE);
              stat.setInt(1, Integer.parseInt(values.get("range")));
              rs = stat.executeQuery();
            } catch(Exception e) {
              return null;
            }
            return rs;
          }
        } catch(Exception e) {
          try {
            out.println("<p>" + e.toString() + "</p>");
          } catch(Exception e1) {
            return null;
          }
          return null;
        }
      }


      /**
       *  Build the default query if no range is given.
       *  @param None
       *  @return the default query
       */
      private String buildDefaultQuery() {
        String query = "SELECT market_name,website,city,state,zipcode FROM markets WHERE";
        if (values.get("market") != null)  query += " market_name = ?";
        if (values.get("city") != null)    query += " city = ?";
        if (values.get("state") != null)   query += " state = ?";
        if (values.get("zipcode") != null) query += " zipcode = ?";
        query += ";";
        return query;
      }


      /**
       *  Build the query to retrieve the latitude and longitude of
       *  the desired market location. Limit results to 3 to increase odds
       *  of getting a latitude and longitude that are valid.
       *  @param None
       *  @return the query, or null if there is no market name,
       *          city or zipcode.
       */
      private String buildRangeQuery() {
        int range = validateRange(this.values.get("range"));
        if (range == -1)
          return null;

        // Build the query to get one market with lat and long
        String query = "SELECT latitude,longitude FROM markets WHERE";
        boolean addOr = false;
        if (values.get("market") != null) {
          query += " market_name = ?";
          addOr = true;
        }
        if (values.get("city") != null) {
          if (addOr)
            query += " OR";
          query += " city = ?";
        }
        if (values.get("zipcode") != null) {
          if (addOr)
            query += " OR";
          query += " zipcode = ?";
        }
        if (query.charAt(query.length() - 1) != '?')
          return null;
        query += " LIMIT 3;";
        return query;
      }


      /**
       *  Buld the string to query the distance away from a certain market.
       *  @param None
       *  @return the query string
       */
      private String buildDistanceQuery() {
        return "SELECT market_name,website,state,city,zipcode," +
               "(3959*acos(cos(radians(@lat)) * cos(radians(latitude)) * cos(radians(longitude)" +
               " - radians(@long)) + sin(radians(@lat)) * sin(radians(latitude)))) AS distance " +
               "FROM markets HAVING distance < ? ORDER BY distance;";
      }


      /**
       *  Check to see if the range value specified can be parsed.
       *  @param range - the range value to parse
       *  @return the range value as an integer, -1 if cannot parse
       */
      private int validateRange(String range) {
        try {
          int retRange = Integer.parseInt(range);
          return retRange;
        } catch(Exception e) {
          return -1;
        }
      }


      /**
       *  Return true if all user entered data is valid and acceptable
       *  for an SQL query statement; that is, zipcode and range must be
       *  nonnegative, and there must at least be a name/location to query.
       *  @return true if the input is valid, false otherwise
       */
      public boolean validInput() {
        if (values.isEmpty()) {
          return false;
        }
        String name  = values.get("market");
        String city  = values.get("city");
        String state = values.get("state");
        String zip   = values.get("zipcode");
        String range = values.get("range");
        if (zip != null) { // Validate the zipcode
          try {
            int zipcode = Integer.parseInt(zip);
            if (zipcode <= 0 || zipcode > 100000) {
              return false;
            }
          } catch(Exception e) {
            return false;
          }
        }

        if (range != null) { // Validate the range input
          try {
            if (!range.equals("")) {
              int val = Integer.parseInt(range);
              if (val <= 0) {
                return false;
              }
            }
          } catch(Exception e) {
            return false;
          }
        }

        // Make sure there is at least an input value to query
        return name != null || city != null || state != null || zip != null;
      }

      /**
       *  Closes the Connection object when database use is complete.
       *  @param None
       *  @return None
       */
      public void closeConnection() {
        try {
          conn.close();
        } catch(Exception e) {
          System.err.println("ERROR: <couldn't close database connection>");
        }
      }
    }
    %>

    <%!
    /*
     To run the program on Apache for local host:
     http://localhost:8090/index.jsp
    */

    /**
     *  Loops from start to end and displays the data from
     *  the ResultSet in the table. It can also go backwards
     *  through the ResultSet to display previous data.
     *  @param out - the JspWriter
     *  @param reverse - true if reverse through data, false otherwise
     *  @exception IOException thrown if cannot write HTML
     *  @exception SQLException if trouble iterating through ResultSet
     */
    public void buildTable(JspWriter out, boolean reverse)
      throws IOException, SQLException {

      out.print("<center><table border='1' cellpadding='2'>");
      out.print("<tr><th>Market</th><th>Website</th><th>State</th><th>City</th><th>Zipcode</th><th>Distance (miles)</th></tr>");
      for (int i = 0; i < 30; i++) {
        if (displayIndex == results.size()) { // Return if reached the end
          out.println("<center><p>Reached the End</p></center>");
          return;
        }
        if (reverse && displayIndex == 0) { // Return if trying to go backwards from beginning
          out.println("<center><p>Can Only Go Forward</p></center>");
          return;
        }
        out.print("<tr>");
        out.print("<td align='center'>" + results.get(displayIndex)[0] + "</td>");
        out.print("<td align='center'>" + results.get(displayIndex)[1] + "</td>");
        out.print("<td align='center'>" + results.get(displayIndex)[2] + "</td>");
        out.print("<td align='center'>" + results.get(displayIndex)[3] + "</td>");
        out.print("<td align='center'>" + results.get(displayIndex)[4] + "</td>");
        out.print("<td align='center'>" + results.get(displayIndex)[5] + "</td>");
        out.print("</tr>");
        if (reverse)
          displayIndex--;
        else
          displayIndex++;
      }
      out.print("</table></center></br>");
      out.println("<center><p>"+displayIndex+"</p></center>");
    }
    %>

    <%
      // Retrieve the input the user entered and validate it
      String[] params = {"market", "city", "state", "zipcode", "range"};
      Map<String, String> values = new HashMap<String, String>();
      for (String param : params) {
        String value = request.getParameter(param);
        if (value != null) {
          if (!value.equals(""))
            values.put(param, value);
        }
      }
      GetMarkets marketGetter = new GetMarkets(values);
      if (marketGetter.validInput()) {
        ResultSet rs = marketGetter.makeQuery(out);
        if (rs == null) {
          out.println("<center><h2>Cannot Find Markets for These Parameters</h2></center>");
        } else {

          // Store all of the results
          while (rs.next()) {
            String[] data = new String[6];
            String name = rs.getString("market_name");
            if (name == null || name.equals(""))   name = "N/A";
            data[0] = name;
            String site = rs.getString("website");
            if (site == null || site.equals(""))   site = "N/A";
            data[1] = site;
            String state = rs.getString("state");
            if (state == null || state.equals("")) state = "N/A";
            data[2] = state;
            String city = rs.getString("city");
            if (city == null || city.equals(""))   city = "N/A";
            data[3] = city;
            int zip = rs.getInt("zipcode");
            String code;
            try {
              code = (zip == -1) ? "N/A" : Integer.toString(zip);
            } catch(Exception e) {
              code = "N/A";
            }
            data[4] = code;
            String dist;
            try {
              dist = rs.getString("distance");
              double d = Double.parseDouble(dist);
              DecimalFormat numberFormat = new DecimalFormat("#.00");
              dist = numberFormat.format(d);
            } catch(Exception e) {
              dist = "N/A";
            }
            data[5] = dist;
            results.add(data);
          }
        }
        try {
          out.println("<center><h2>Markets Found</h2></center>");
          out.println("<center><p>Click Next or Previous</p></center>");
        } catch(Exception e) {
          out.print("<center><p>" + e.toString() + "</p></center>");
        }

    %>
    <form method="POST">
      <center>
        <input type="submit" name="previous_table" value="Previous" />
        <input type="submit" name="next_table" value="Next" />
        <input type="submit" name="clear" value="Clear Old Results" />
      </center>
    </form>
    </br>

    <%
          String val1 = request.getParameter("previous_table");
          String val2 = request.getParameter("next_table");
          String val3 = request.getParameter("clear");
          try {
            if (val3 != null) {
              displayIndex = 0;
              results.clear();
            }
            if (val1 != null) { // Get previous results
              buildTable(out, true);
            }
            else if (val2 != null) { // Get next results
              buildTable(out, false);
            }
          } catch(Exception e) {
            out.print("<center><h1>" + e.toString() + "</h1></center>");
          }
        }
    %>
  </body>

</html>
