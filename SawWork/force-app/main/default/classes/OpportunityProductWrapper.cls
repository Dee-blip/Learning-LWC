/**
 * utility class for OpportinityAddLineItems.cls & OpportinityAddLineItemsForecasting.cls
 * wraps the product2 object with checkbox and 
 * pricing, so it can be added and removed from lists.
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Dan Pejanovic    1/2010      Created Class
 * Karteek Kumar M	21/2010		CR 659773 Allow forecast category and sales stage to be overriden by the sales reps
 								Changed the type of all class members to String.
 * Karteek Kumar M  11/01/2011  CR 874109 Updates to Oppty Product Wizard   
 								   -) Added Revenue Impact field in 3 places    
 * Ali KM			16/02/2012	CR 1477954 Forecasting: Need to update QA env for forecasting
 									-> Added a new Recurring Type=MRR; used for OOTB Forecasting customizations.
 									-> Added a new Field: oneTimeFee this is mapped to Oppty-Product.NRR.
  								   								
 **/
public class OpportunityProductWrapper {

    
    public Boolean checked{ get; set;}
    public Product2 p { get; set;}
    public String price { get; set;}
    public string recurring {get;set;}
    public string oneTimeFee {get;set;}
    public string noOfMos {get;set;}
    public string noOfApps {get;set;}
    public string lmrrType {get;set;}
    public string revImpact {get;set;}
    public OpportunityProductWrapper (OpportunityProductWrapper w) {
        p= w.p;
        checked = w.checked;
        price = '0';
        noOfMos = '1';
        noOfApps = '0';
        lmrrType = '';
        // Forecasting changes below:
        //SFDC-2686
        if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled'))
        {
        	recurring = 'MRR';
        	oneTimeFee='0';
        }
        // Forecasting changes end ---
        else
       		recurring = 'GMRR';
    }
    //constructors /mutiple signatures
    public OpportunityProductWrapper(){
        p = new Product2();
        checked=false;
    }
    // just product, assume unchecked
    public OpportunityProductWrapper(Product2 prod){
        p = prod;
        checked=false;
    }
    // checked status passed in
    public OpportunityProductWrapper(Boolean ck, Product2 prod){
        p = prod;
        checked=ck;
    }
   //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //test method
    //public static testMethod void testMe() {
 
    //    OpportunityProductWrapper w1 = new OpportunityProductWrapper();
    //    System.assertEquals(w1.checked,false);
    //    OpportunityProductWrapper w2 = new OpportunityProductWrapper(new Product2(name='Test1'));
    //    System.assertEquals(w2.p.name,'Test1');
    //    System.assertEquals(w2.checked,false);
    //    OpportunityProductWrapper w3 = new OpportunityProductWrapper(true, new Product2(name='Test3'));
    //    System.assertEquals(w3.p.name,'Test3');
    //    System.assertEquals(w3.checked,true); 
    //    OpportunityProductWrapper w4 = new OpportunityProductWrapper(w3);
    //    System.assertEquals(w4.p.name,'Test3');
    //    System.assertEquals(w4.checked, true);  
    //}
}