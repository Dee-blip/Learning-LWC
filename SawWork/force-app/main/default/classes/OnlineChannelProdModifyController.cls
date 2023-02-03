/***
OnlineChannelProdModifyController
This Controller is for the OnlineChannelProductModify page. This page is used to add a new currency with the prduct and the tier deatils frozen.

Pramod Kamath Voderbet         Release 3.44     CR 2703234- Online Channel: New Pricing Type - Cloudlets

Ruchika Sharma                 Release 4.0      CR 2733897 - Online Channel: New Pricing Type - Commit with Multiple UOMs

Ruchika Sharma                 Release 4.1      CR 2801910- Marketplace : 4.1                          

Ruchika Sharma                 Release 4.6      CR 2946116 - Change number of tiers for pricing type clodulets
***/

public with sharing class OnlineChannelProdModifyController {

      public String    pkgId { get; set;}
      public String    prodId { get; set;}
      public String    priceId { get; set;}
       public String    view { get; set;}
      public Online_Channel_Package_Product__c campProd {get;set;}
      public Online_Channel_Package_Pricing__c campPrice {get;set;} 
      
      public OnlineChannelProdModifyController(ApexPages.StandardController controller) {
    
      pkgId = ApexPages.currentPage().getParameters().get('pkgId');
      prodId = ApexPages.currentPage().getParameters().get('prodId'); 
      priceId = ApexPages.currentPage().getParameters().get('zpriceId'); 
        view = ApexPages.currentPage().getParameters().get('view');     
     
     if(priceId=='null')
     {
     campPrice=new Online_Channel_Package_Pricing__c();
     }
         else
         {//query the price. 
         //SELECT baseprice__c,ConnectionReceivedId,ConnectionSentId,CreatedById,CreatedDate,CurrencyIsoCode,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Name,Online_Channel_Package_Product__c,overage_price__c,simple_usg_price__c,SystemModstamp,t1_overage_price__c,t1_price__c,t2_overage_price__c,t2_price__c,t3_overage_price__c,t3_price__c,t4_overage_price__c,t4_price__c,t5_overage_price__c,t5_price__c,t6_overage_price__c,t6_price__c,t7_overage_price__c,t7_price__c,t8_overage_price__c,t8_price__c,t9_overage_price__c,t9_price__c,t10_overage_price__c,t10_price__c FROM Online_Channel_Package_Pricing__c
         //CR 2801910 : Ruchika Sharma: Added newly created fields in the select statement.
         campPrice=[SELECT baseprice__c,CurrencyIsoCode,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Name,Online_Channel_Package_Product__c,overage_price__c,simple_usg_price__c,SystemModstamp,t1_overage_price__c,t1_price__c,t2_overage_price__c,t2_price__c,t3_overage_price__c,t3_price__c,t4_overage_price__c,t4_price__c,t5_overage_price__c,t5_price__c,t6_overage_price__c,t6_price__c,t7_overage_price__c,t7_price__c,t8_overage_price__c,t8_price__c,t9_overage_price__c,t9_price__c,t10_overage_price__c,t10_price__c, Cloudlet_Pricing_unit1__c, Cloudlet_Pricing_unit2__c, Cloudlet_Pricing_unit3__c FROM Online_Channel_Package_Pricing__c where id =:priceId][0];
         }
     
    // CR 2733897, CR 2946116s : Ruchika Sharma: Added newly created fields in the select statement.
    campProd = [Select Billing_Cycle__c,mbps_high_quantity_t1__c,mbps_high_quantity_t2__c,mbps_high_quantity_t3__c, mbps_high_quantity_t4__c, mbps_high_quantity_t5__c, mbps_high_quantity_t6__c, mbps_high_quantity_t7__c, mbps_high_quantity_t8__c, mbps_high_quantity_t9__c, mbps_high_quantity_t10__c, mpv_low_quantity_t1__c, mpv_low_quantity_t2__c, mpv_low_quantity_t3__c, mpv_low_quantity_t4__c, mpv_low_quantity_t5__c, mpv_low_quantity_t6__c,mpv_low_quantity_t7__c, mpv_low_quantity_t8__c, mpv_low_quantity_t9__c, mpv_low_quantity_t10__c, mpv_high_quantity_t7__c, mpv_high_quantity_t8__c, mpv_high_quantity_t9__c, mpv_high_quantity_t10__c, mpv_high_quantity_t1__c, mpv_high_quantity_t2__c, mpv_high_quantity_t3__c, mpv_high_quantity_t4__c, mpv_high_quantity_t5__c, mpv_high_quantity_t6__c,id,name,Trial_Quantity__c,t1_usage_quant_low__c,t1_usage_quant_high__c,t2_usage_quant_low__c,t3_usage_quant_high__c,t3_usage_quant_low__c,t2_usage_quant_high__c,t4_usage_quant_high__c,t4_usage_quant_low__c,t5_usage_quant_high__c,t5_usage_quant_low__c,t6_usage_quant_high__c,t6_usage_quant_low__c,t7_usage_quant_high__c,t7_usage_quant_low__c,t8_usage_quant_high__c,t8_usage_quant_low__c,t9_usage_quant_high__c,t9_usage_quant_low__c,Quantity_Base_UOM__c,Online_Channel_Package__c,Usage_Type__c,UOM__c,MPID__c,Sec_MPID__c,t1_commit_quantity__c,t2_commit_quantity__c,t3_commit_quantity__c,t4_commit_quantity__c,t5_commit_quantity__c,t6_commit_quantity__c,t7_commit_quantity__c,t8_commit_quantity__c,t9_commit_quantity__c,t10_commit_quantity__c,t10_usage_quant_high__c,t10_usage_quant_low__c, UOM1__c, UOM2__c, Trial_Quantity1__c, Trial_Quantity2__c, Billing_Cycle1__c, Billing_Cycle2__c from Online_Channel_Package_Product__c where id=:prodId ];
   
    }
    
    public PageReference save() { 
    
     Boolean savedSuccessfully;
     
     try
     {
           campPrice.Online_Channel_Package_Product__c= campProd.Id;
           campPrice.Name = campPrice.CurrencyIsoCode;//'USD';
          upsert campPrice; 
          savedSuccessfully=true;     
          
      }         
       
       //this is to prvent duplicate currency from being added.
       catch(DmlException e)
     {
     if(e.getMessage().contains('DUPLICATE_VALUE'))
     {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Currency already exists for the Product'); 
        //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); 
        ApexPages.addMessage(myMsg);
        savedSuccessfully = false;
     }
        
     }
     
     
     if(savedSuccessfully)
     {       
          String rUrl = '/' + ApexPages.currentPage().getParameters().get('prodId');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            return rPage; 
            
      }
      else
       return null;
    
  }
  
  
   public PageReference cancel() {
   
   String rUrl = '/' + ApexPages.currentPage().getParameters().get('prodId');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            return rPage;  
  } 
  
  

  
  
  public PageReference saveandaddpro() {
  
   Boolean zsavedSuccessfully;  
  
   try
     {
           campPrice.Online_Channel_Package_Product__c= campProd.Id;
           campPrice.Name = campPrice.CurrencyIsoCode;//'USD';
          upsert campPrice;
          zsavedSuccessfully=true; 
      }
      
      
      catch(DmlException e)
     {
     if(e.getMessage().contains('DUPLICATE_VALUE'))
     {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Currency already exists for the Product'); 
        //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); 
        ApexPages.addMessage(myMsg);
        zsavedSuccessfully = false;
     }
 }
       
   
   if(zsavedSuccessfully)
   {
   //try setting params thru functions. 
   String rUrlx = '/apex/OnlineChannelProductModify?pkgId=' + ApexPages.currentPage().getParameters().get('pkgId') + '&prodId='  +campProd.Id  + '&zpriceId=null';
            PageReference rPage = new PageReference(rUrlx);
           rPage.setRedirect(true);
            return rPage;      
  }
  else
  return null;
  
  } 

}