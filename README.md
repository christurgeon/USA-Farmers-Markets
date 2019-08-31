# Overview
Search USA farmers markets in your area or in an area that you are travelling to. Optionally supply a range in order to narrow your search. This application makes use of pagination to allow the user to iterate forward or backwards through search results.

## Installation
1. Run```build_script.sql``` locatd ```scripts``` in order to construct the database.
2. Place the ```mysql-connector-java-8.0.17.jar``` file or whatever version you use within ```CATALINA_HOME/lib``` folder within Tomcat (e.g. Tomcat9/lib).
3. Run the script ```load_database.cmd``` located in the ```scripts``` folder in order to load the database.
4. Copy the WAR file to ```CATALINA_HOME/webapps``` then copy all remaining files and put them into the ```ROOT``` folder within the aforementioned directory. This must be done so the ```JSP``` file can access database credentials in ```credentials.txt```.
5. Put your SQL username and password into ```credentials.txt``` in the form USERNAME:PASSWORD.
6. Start the Tomcat server.
7. For port number 8090, paste ```http://localhost:8090/markets/index.jsp``` into your browser to run the application locally.


### Development Information
* OS: Windows 10 
* Java: jdk1.8.0_191
* Tomcat Port: localhost:8090
