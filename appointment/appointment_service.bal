import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;
import ballerina/jwt;

configurable string dbHost = "localhost";
configurable string dbUser = "root";
configurable string dbPass = "password";


mysql:Client dbClient = check new (host = dbHost, user = dbUser, password = dbPass, database = "appointment_db");

service /appointment on new http:Listener(9091) {

    resource function post book(http:Caller caller, http:Request req) returns error {
        json payload = check req.getJsonPayload();
        string token = check req.getHeader("Authorization");
        
        jwt:ValidatorConfig config = {
            issuer: "ballerina",
            audience: "ballerinaUsers",
            signatureConfig: {
                key: "secretKey",
                algorithm: jwt:HS256
            }
        };

        var validation = jwt:validate(token, config);
        if (validation is jwt:DecodedJwt) {
            string username = validation.payload.sub.toString();
            
            string serviceProvider = (check payload.serviceProvider).toString();
            string appointmentDate = (check payload.appointmentDate).toString();
            string appointmentTime = (check payload.appointmentTime).toString();
            
            
            string query = "SELECT id FROM users WHERE username = ?";
            stream<sql:Row, error> userStream = dbClient->query(query, username);
            sql:Row? userRow = userStream.next();
            if userRow is sql:Row {
                int userId = check userRow.id.toInt();

                
                string insertQuery = "INSERT INTO appointments (user_id, service_provider, appointment_date, appointment_time, status) VALUES (?, ?, ?, ?, 'booked')";
                _ = check dbClient->execute(insertQuery, userId, serviceProvider, appointmentDate, appointmentTime);
                
                json response = { message: "Appointment booked successfully" };
                check caller->respond(response);
            }
        } else {
            check caller->respond({ message: "Unauthorized" });
        }
    }

    resource function get all(http:Caller caller, http:Request req) returns error? {
        json[] appointments = [];
        string query = "SELECT * FROM appointments";
        stream<sql:Row, error> resultStream = dbClient->query(query);
        sql:Row? row;
        while row = resultStream.next() {
            if row is sql:Row {
                appointments.push({
                    id: row.id,
                    serviceProvider: row.service_provider,
                    appointmentDate: row.appointment_date,
                    appointmentTime: row.appointment_time,
                    status: row.status
                });
            }
        }
        check caller->respond(appointments);
    }
}
