/***
CampaignProdExtnController
@author :Pramod Kamath Voderbet
@Description : This class is the controller for NewCampaignProd visual Force page. 
This page will be used as a part of the AkamaiOnline project and will be used to add new Campaign Products under the Campain Object. 


    @History
    --Developer              --Date           --Change
    Pramod Kamath Voderbet  23rd April 2013    First Release
    Pramod Kamath Voderbet                      Beta Release Changes
    Pramod Kamath               31st March 2014   3.40

***/
public with sharing class campaignProdExtnController
{
    //public static campId;
    public String campId { get; set;}
     public String campprodtype { get; set;}
    public Campaign_Product__c campProd {get;set;}
    public Campaign_Pricing__c campPrice {get;set;} 
    //public Online_Channel_Message__c ocmsg {get;set;} 
    
  
    public campaignProdExtnController(ApexPages.StandardController controller) 
    {
       campPrice=new Campaign_Pricing__c();
     //  ocmsg = new Online_Channel_Message__c();
       campId = ApexPages.currentPage().getParameters().get('cId'); 
       campprodtype=ApexPages.currentPage().getParameters().get('prodtype');       
       campProd = new Campaign_Product__c();
     campProd.Campaign__c = campId; 
                          
    }   
    
    public PageReference save() {    
    
       
       insert campProd;
       //Campaign_Product__c cp = [select Id from Campaign_Product__c where Campaign_product__c.Campaign__c =: campId][0];
       //Id cProdId = cp.Id;
       //if(string.ValueOf(cProdId) != null && string.valueOf(cProdId) != '')
       //{
           campPrice.Campaign_Product__c = campProd.Id;
           campPrice.CurrencyIsoCode ='USD';
           campPrice.Name = campPrice.CurrencyIsoCode;//'USD';
          insert campPrice;          
       //}
       //insert campPrice;
       
      // ocmsg.Online_Channel_Product__c = campProd.Id;
       //insert ocmsg;
         
       
          String rUrl = '/' + ApexPages.currentPage().getParameters().get('cId');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            return rPage; 
    
  }
  
  
   public PageReference cancel() {
   
   String rUrl = '/' + ApexPages.currentPage().getParameters().get('cId');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            return rPage;      
  
    
  }  
  
  
    
  }