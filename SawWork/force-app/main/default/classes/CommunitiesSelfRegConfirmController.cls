/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
public with sharing class CommunitiesSelfRegConfirmController {
    public String newUrl{get;set;}
    public CommunitiesSelfRegConfirmController() {
    newUrl ='/apex/CommunitiesLogin?startURL=%2F%3Fdc%3DAll%26criteria%3DALLQUESTIONS%26feedtype%3DRECENT%26&';
    }
}