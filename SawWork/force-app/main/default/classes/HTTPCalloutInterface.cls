/***
    HTTPCalloutInterface
    
    @autor : Pranav Moktali <prmoktal@akamai.com>
    @Description :
    This is an interface class for http callouts. 
    Will help to talk to other systems using RESTful services. 
    
*/

public interface HTTPCalloutInterface {
    void callGET(String requestURL);
    void callPOST(String requestURL, String requestBody);
    void callPUT(String requestURL, String requestBody);
    void callDELETE(String requestURL);
}