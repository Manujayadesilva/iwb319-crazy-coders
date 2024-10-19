service /notification on new http:Listener(9092) {

    resource function post sendSMS(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        string phoneNumber = payload.phoneNumber.toString();
        string message = payload.message.toString();
        
        
        json response = { message: "SMS sent successfully to " + phoneNumber };
        check caller->respond(response);
    }
}
