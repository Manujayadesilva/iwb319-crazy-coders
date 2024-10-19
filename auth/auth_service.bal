import ballerina/http;
import ballerina/jwt;
import ballerina/sql;
import ballerinax/mysql;
import ballerina/log;

configurable string dbHost = "localhost";
configurable string dbUsername = "root";
configurable string dbPassword = "password";
configurable string dbName = "appointment_db";

mysql:Client dbClient = check new (host=dbHost, user=dbUsername, password=dbPassword, database=dbName);


type User record {
    int id;
    string username;
    string password;
};

service /auth on new http:Listener(9090) {

    
    resource function post login(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        string username = (check payload.username).toString();
        string password = (check payload.password).toString();
        
        
        sql:ParameterizedQuery query = `SELECT id, username, password FROM users WHERE username = ${username} AND password = ${password}`;
        stream<User, sql:Error?> resultStream = dbClient->query(query);
        
        
        var result = resultStream.next();
        if result is record {| User value; |} {
            User user = result.value;

           
            jwt:Header jwtHeader = {alg: jwt:HS256};  
            jwt:Payload jwtPayload = {
                iss: "ballerina",
                sub: user.username
            };
            string secretKey = "secretKey";
            string jwtToken = check jwt:sign(jwtHeader, jwtPayload, secretKey); 
            
            json response = { token: jwtToken };
            check caller->respond(response);
        } else {
            check caller->respond({ message: "Invalid username or password" });
        }
    }

    
    resource function post register(http:Caller caller, http:Request req) returns error? {
        json payloadJson = check req.getJsonPayload();
        string username = (check payloadJson.username).toString();
        string password = (check payloadJson.password).toString();
        
        
        sql:ParameterizedQuery query = `INSERT INTO users (username, password) VALUES (${username}, ${password})`;
        _ = check dbClient->execute(query);
        
        json response = { message: "User registered successfully" };
        check caller->respond(response);
    }
}
