/*

   Author - Anand Hegde Aug 19th 2016
   */


public class CurrentSalesChannelWrapper{

    public Current_Sales_Channel__c csc;
    public String key;
    public Boolean needsUpdate=false;
    public Boolean needsToBeDeleted = false;
    public Set<String> products = new Set<String>();


    public CurrentSalesChannelWrapper(Current_Sales_Channel__c csc)
    {
        this.csc = csc;
        this.key=csc.CurrentSalesChannelExternalID__c;
        this.products.addAll(csc.Products_Contracted__c.split(';'));
        System.Debug(LoggingLevel.Error, 'Get Existing  '+csc);

    }

    public CurrentSalesChannelWrapper(Merge_contract_header__c mch,String mchkey,Map<Merge_contract_header__c,Boolean> mchToDoNotContactFlagMap)
    {
           //csc = new Current_Sales_Channel__c(Has_Partner_Prohibited_Marketing__c=( mch.get('Do_Not_Contact_Indirect_Customers__c')==true ? true : false ), Customer_Account__c=(Id)mch.get('Account_Name__c'), Partner_Account__c=(Id)mch.get('Parent_Account_Name__c'));
        System.Debug(LoggingLevel.Error, 'Inside  Wrapper Class '+mchkey);
        String partnerAccount = mchkey.substringAfter('#');
        System.Debug(LoggingLevel.Error, ' String value '+partnerAccount);
    
            
        if(partnerAccount != 'null')
          csc = new Current_Sales_Channel__c(Has_Partner_Prohibited_Marketing__c=( mchToDoNotContactFlagMap.get(mch)==true ? true : false ), Customer_Account__c=(Id)mch.Account_Name__c, Partner_Account__c= partnerAccount);
      else
            csc = new Current_Sales_Channel__c(Has_Partner_Prohibited_Marketing__c=( mchToDoNotContactFlagMap.get(mch)==true ? true : false ), Customer_Account__c=(Id)mch.Account_Name__c);
           
        System.Debug(LoggingLevel.Error, 'AGH_D new creation '+csc);
           if(mch.get('Contract_Type__c') == 'Direct Customer')
              {
                  if(csc.Customer_Account__c==csc.Partner_Account__c)
                  csc.Partner_Account__c=null;
                  this.key = csc.Customer_Account__c+'#'+csc.Partner_Account__c;
                  System.Debug(LoggingLevel.Error, 'Inside Direct Customer  '+csc);

              }
           else 
              this.key = mchkey;  
           System.Debug(LoggingLevel.Error, 'AGH_D Key '+this.key);
 
        csc.CurrentSalesChannelExternalID__c=this.key;
    }


    public void addProduct(String newProduct)
    {
        this.products.add(newProduct);
    }

    public void removeProduct(String productToBeRemoved)
    {
        this.products.remove(productToBeRemoved);
    }

    public void addProducts(Set<String> prods)
    {
        this.products.addAll(prods);
    }
    
    public void addDates(Date OEED,Date YEED)
    {
        this.csc.Oldest_Effective_End_Date__c = OEED;
        this.csc.Youngest_Effective_End_Date__c = YEED;
    }

    public Boolean equals(CurrentSalesChannelWrapper otherCSCWrapper)
    {
        System.Debug(LoggingLevel.Error, 'Hitesh  Equal method 2 '+this.csc.Oldest_Effective_End_Date__c +' Date 2 '+otherCSCWrapper.csc.Oldest_Effective_End_Date__c +'Date 3 '+this.csc.Youngest_Effective_End_Date__c +'Date 4 '+otherCSCWrapper.csc.Youngest_Effective_End_Date__c);
        //SFDC-1481
        return this.csc.Customer_Account__c==otherCSCWrapper.csc.Customer_Account__c && this.csc.Partner_Account__c==otherCSCWrapper.csc.Partner_Account__c && this.products.equals(otherCSCWrapper.products) && this.csc.Has_Partner_Prohibited_Marketing__c==otherCSCWrapper.csc.Has_Partner_Prohibited_Marketing__c && this.csc.Youngest_Effective_End_Date__c == otherCSCWrapper.csc.Youngest_Effective_End_Date__c && this.csc.Oldest_Effective_End_Date__c == otherCSCWrapper.csc.Oldest_Effective_End_Date__c && this.csc.Partner_Client_Manager__c == otherCSCWrapper.csc.Partner_Client_Manager__c;
    }

    public void setUpdateNeeded()
    {
        this.needsUpdate=true;
    }
    
    //SFDC-1481 - set partner client manager
    public void addPartnerClientManager(String pcm){
      this.csc.Partner_Client_Manager__c = pcm;
      System.Debug(LoggingLevel.Error,'this.csc.Partner_Client_Manager__c: '+this.csc.Partner_Client_Manager__c);
    }
    public Current_Sales_Channel__c getCSCRecord()
    {
        List<String> productsList = new List<String>();
        productsList.addAll(this.products);
        this.csc.Products_Contracted__c=String.join(productsList, ';');
        
        return this.csc;
    }
}