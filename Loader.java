//package tools;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.sql.*;

/*
Compiling and running the database loader
javac -cp ".;C:\Users\turgec\OneDrive\CS\App Progamming\Homework\hw5\markets\src\mysql-connector-java-8.0.17\mysql-connector-java-8.0.17.jar" Loader.java
java -cp ".;C:\Users\turgec\OneDrive\CS\App Progamming\Homework\hw5\markets\src\mysql-connector-java-8.0.17\mysql-connector-java-8.0.17.jar" Loader
*/

public class Loader {

  private static final String file = "Markets.csv";
  private static BufferedReader reader;

  public Loader() {

    // Connect to the JDBC
    String url = "jdbc:mysql://localhost:3306/farmers_markets";
    Connection conn = null;
    try {
      conn = DriverManager.getConnection(url, "USERNAME", "PASSWORD");
    } catch(SQLException e) {
      e.printStackTrace();
      System.err.println("ERROR: <couldn't connect to database>");
      System.exit(1);
    }

    // Read in the data from the Markets.csv file and load it into the database
    try {
      String line;
      reader = new BufferedReader(new FileReader(file)); // Skip the first line
      reader.readLine();
      while ((line = reader.readLine()) != null) {
        String insert = "INSERT INTO markets (markets_id,market_name,website,state,city,zipcode,latitude,longitude)"
                        + "VALUES (?,?,?,?,?,?,?,?)";

        // Use regulat expressions to avoid splitting comma's within strings
        String[] tokens = line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", -1);
        PreparedStatement stat = conn.prepareStatement(insert);
        stat.setInt(1, Integer.parseInt(tokens[0]));  // id
        stat.setString(2, tokens[1]);                 // name
        stat.setString(3, tokens[2]);                 // website
        stat.setString(4, tokens[10]);                // city
        stat.setString(5, tokens[8]);                 // state
        int zip = handleZip(tokens[11]);
        stat.setInt(6, zip);                          // zipcode

        // Parse latitude and longitude, set to default if issue arises
        try {
          stat.setDouble(7, Double.parseDouble(tokens[21]));  // latitude
          stat.setDouble(8, Double.parseDouble(tokens[20]));  // longitude
        } catch(Exception e) {
          stat.setDouble(7, 0); // If no value supplied set 0,0
          stat.setDouble(8, 0); // If no value supplied set 0,0
        }
        stat.execute();
      }

    // Print out the error details
    } catch(Exception e) {
      System.err.println("ERROR: <trouble loading into database>");
      e.printStackTrace();
      System.exit(1);
    } finally {

      // Close the reader
      try {
        if (reader != null) {
          reader.close();
        }
      } catch(IOException e) {
        System.err.println("ERROR: <couldn't close reader>");
      }
    }
  }


  /**
   *  Ensures that a zip code is the right size
   *  @param zip - the zipcode as a string
   *  @return return the zipcode as an integer
   */
  private int handleZip(String zip) {

    // Try to parse the first 5 digits
    if (zip.length() >= 5) {
      try {
        return Integer.parseInt(zip.substring(0, 5));
      } catch(NumberFormatException e) {
        return -1;
      }
    }

    // Return -1 for empty zipcodes
    else if (zip.equals(""))
      return -1;

    // Parse the entire zipcode, if trouble, return -1
    else
      try {
        return Integer.parseInt(zip);
      } catch(NumberFormatException e) {
        return -1;
      }
  }


  // Call the main method from the command line or the script to populate the database
  public static void main(String[] args) {
    Loader loader = new Loader();
  }
}
