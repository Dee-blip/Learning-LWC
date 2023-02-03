/***
    PACE_UserSpecificHomepageController
    @version 1.0
    @author Hitesh Chawda <hchawda@akamai.com> and Nagdeep Kodandaram <nakodand@akamai.com>
    @Description : This Class is used for controlling the User Specific PACE landing Page.
    @History
    --Developer           --Date            --Change
    Hitesh Chawda          09-12-2012       1978984
    Nagdeep Kodandaram
*/
public with sharing class PACE_UserSpecificHomepageController  {

public String userId;
public String userName {get; set;}
public String division {get; set;}
public String productline {get; set;}
public String division_con {get; set;}
public String productline_con {get; set;}
public String activation {get; set;}
public String reviewmonth {get; set;}
public String activeli {get; set;}
public List<PACE_Program__c> programMProgramList{get; set;}
//public List<PACE_Concept__c> programMConceptList{get; set;}

public List<Launch_Item__c> programMcatalogUpdateList {get; set;}
public List<PACE_Review_Calendar__c> progrmMreviewCalendarList {get; set;}
public List<Contingency__c> progrmMcontingencyList {get; set;}
public List<Launch_Item__c> activeLaunchItemList {get; set;}
public List<Launch_Item_Approval__c> launchItemApproval {get; set;}


public List<PACE_Program__c> programManProgramList{get; set;}
//public List<PACE_Concept__c> programManConceptList{get; set;}
public List<Launch_Item__c> productMancatalogUpdateList {get; set;}
public List<Launch_Item__c> activemyLaunchItemList {get; set;}
public List<PACE_Review_Calendar__c> rcShowList {get; set;} 
public List<Contingency__c>  myContingenctList {get; set;}


public Boolean isUserProfilePM{get; set;}
public List<String> productLineList;
public List<Product_Line__c> productlines {get; set;}
Public List<PLU__c> activationlist {get; set;}

public PACE_UserSpecificHomepageBaseClass basecls{get; set;} 
public datetime myDateTime {get; set;}
public date today_date {get; set;}
public Integer today_day {get; set;} 
public Integer today_month {get; set;}
public Integer today_year {get; set;}
public string format_date {get; set;}
    
    
    
Set<Id> progrmaidset = new Set<Id>();
Set<Id> reviewCalendarset = new Set<Id>();
List<PACE_Phase__c> phaseList;
List<PACE_Program__c> programList;
//List<PACE_Concept__c> conceptList;
List<Launch_Item__c> catalogUpdateList;
List<PACE_Review_Calendar__c> reviewCalendarList;
List<Contingency__c> contingencyList;

public PACE_UserSpecificHomepageController()
{
    
    programMProgramList = new List<PACE_Program__c>();
    //programMConceptList = new List<PACE_Concept__c>();
    programMcatalogUpdateList = new List<Launch_Item__c>();
    activeLaunchItemList = new List<Launch_Item__c>(); 
    progrmMreviewCalendarList = new List<PACE_Review_Calendar__c>();
    progrmMcontingencyList = new List<Contingency__c>();
    launchItemApproval = new List<Launch_Item_Approval__c>();
    productLineList = new List<String>();
   

    isUserProfilePM =false;
    myDateTime = Datetime.now();
    today_day=myDateTime.day();
    today_month=myDateTime.Month();
    today_year=myDateTime.Year();

    
       string mon_str;
    if(today_month<10){
        mon_str='0'+today_month;
    }
    else
        mon_str=today_month+'';
        
    string day_str;
    if(today_day<10){
        day_str='0'+today_day;
    }
    else
        day_str=today_day+'';    
        
    format_date = 'Review_Date__c >='+ today_year+'-'+mon_str+'-'+day_str;

    division='all';
    productline='all';
    division_con='all';
    productline_con='all';
    activation='all';
    reviewmonth='all';
    activeli='none';
    basecls = new PACE_UserSpecificHomepageBaseClass();
    userId = basecls.userId;
    userName=UserInfo.getName();
    
    productlines = basecls.getObjectList('Product_Line__c','','');
    activationlist = basecls.getObjectList('PLU__c','Archive__c = False ','PLU_Date__c');
   
  
    
    programManProgramList = new List<PACE_Program__c>();
   // programManConceptList = new List<PACE_Concept__c>();
    productMancatalogUpdateList = new List<Launch_Item__c>();
    activemyLaunchItemList = new List<Launch_Item__c>(); 
    rcShowList = new List<PACE_Review_Calendar__c>();
    myContingenctList = new  List<Contingency__c>();
    
    callqueries();


}



//This allows moving between the general and specific page
public PageReference changestate() {
        isUserProfilePM= !isUserProfilePM;
        return null;
    }

// The methods required for the Prodct Line and Division dropdowns
public String getProductline() {
        return productline;
    }

public void setProductline(String productline) {
    System.Debug('Product Line Update has called'+productline);
        this.productline = productline;
    }
    
public String getProductline_con() {
        return productline_con;
    }

public void setProductline_con(String productline_con) {
        this.productline_con = productline_con;
    }
  
public List<SelectOption> getPlitems() {
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('all','All'));
         for(Product_Line__c plValue : productlines)
            {
                options.add(new SelectOption(plValue.Id,plValue.Name));
            }
            
         return options;
    }
    
public String getDivision() {
        return division;
    }

public void setDivision(String division) {
        this.division = division;
    }

public String getDivision_con() {
        return division_con;
    }

public void setDivision_con(String division_con) {
        this.division_con = division_con;
    }


public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('all','All Division'));
        options.add(new SelectOption('Media','Media'));
        options.add(new SelectOption('Service and Support','Service and Support'));
        options.add(new SelectOption('Web Experience','Web Experience'));
        options.add(new SelectOption('Emerging Products','Emerging Products'));
        options.add(new SelectOption('Carrier Products','Carrier Products'));
        return options;
    }



public String getActivation() {
        return activation;
    }

public void setActivation(String activation) {
        this.activation = activation;
    }

public List<SelectOption> getActitems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('all','All'));
        for(PLU__c plu : activationlist)
            {
                options.add(new SelectOption(plu.Id,plu.Name));
            }
            
        return options;
    }


public String getReviewmonth() {
        return reviewmonth;
}

public void setReviewmonth(String reviewmonth) {
        this.reviewmonth = reviewmonth;
}

public List<SelectOption> getMonthitems() {
              List<SelectOption> options = new List<SelectOption>();
              options.add(new SelectOption('all','All'));
              options.add(new SelectOption('January','January'));
              options.add(new SelectOption('February','February'));
              options.add(new SelectOption('March','March'));
              options.add(new SelectOption('April','April'));
              options.add(new SelectOption('May','May'));
              options.add(new SelectOption('June','June'));
              options.add(new SelectOption('July','July'));
              options.add(new SelectOption('August','August'));
              options.add(new SelectOption('September','September'));
              options.add(new SelectOption('October','October'));
              options.add(new SelectOption('November','November'));
              options.add(new SelectOption('December','December'));
            
            return options;
}


public List<SelectOption> getMymonthitems() {
              List<SelectOption> options = new List<SelectOption>();
              options.add(new SelectOption('all','All'));
              options.add(new SelectOption('myvents','My Events'));
              options.add(new SelectOption('January','January'));
              options.add(new SelectOption('February','February'));
              options.add(new SelectOption('March','March'));
              options.add(new SelectOption('April','April'));
              options.add(new SelectOption('May','May'));
              options.add(new SelectOption('June','June'));
              options.add(new SelectOption('July','July'));
              options.add(new SelectOption('August','August'));
              options.add(new SelectOption('September','September'));
              options.add(new SelectOption('October','October'));
              options.add(new SelectOption('November','November'));
              options.add(new SelectOption('December','December'));
            
            return options;
}


public String getActiveli() {
        return activeli;
}

public void setActiveli(String activeli) {
        this.activeli = activeli;
}

public List<SelectOption> getActiveitems() {
    
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('none','Select a Catalog Update'));
        for(Launch_Item__c lic :  activeLaunchItemList)
             {
                  options.add(new SelectOption(lic.Id,lic.Name));
             }
            
         return options;
}

public List<SelectOption> getActivemyitems() {
    
            
          List<SelectOption> options = new List<SelectOption>();
          options.add(new SelectOption('none','Select a Catalog Update'));
          for(Launch_Item__c lic :  activemyLaunchItemList)
              {
                  options.add(new SelectOption(lic.Id,lic.Name));
              }
            
          return options;
}

public void getApprovalTesks() {
        launchItemApproval.clear();
        if(activeli != 'none')
        {
            for(Launch_Item_Approval__c li: [Select Id,Function__c,Approver__r.Name,Approver__c,Delegate_Approver__c,Delegate_Approver__r.Name,Status__c,Comments__c,Launch_Item__c From Launch_Item_Approval__c Where Launch_Item__c = :activeli AND isVisible__c= true ])
            {
                launchItemApproval.add(li);
            }
        }
}
public void callqueries()
{

      List<sOBject> objList = new List<PACE_Program__c>();
     // List<sObject> conList = new List<PACE_Concept__c>();
      List<sObject> liList = new List<Launch_Item__c>();
      List<sObject> rcList = new List<PACE_Review_Calendar__c>();
      List<sObject> continList = new List<Contingency__c>();
      
      
      phaseList= new List<PACE_Phase__c>();
            
      objList = basecls.getObjectList('PACE_Program__c','Status__c != \'Completed\' ','');
      programList = (List<PACE_Program__c>)objList;
      
     // conList = basecls.getObjectList('PACE_Concept__c','Status__c != \'Completed\' ','');
     // conceptList = (List<PACE_Concept__c>)conList;
      
      liList = basecls.getObjectList('Launch_Item__c','Archive__c = False ','');
      catalogUpdateList = (List<Launch_Item__c>)liList;
      
      rcList = basecls.getObjectList('PACE_Review_Calendar__c',format_date,''); //Review_Date__c >\''+today_date+'\'MONTH(Review_Date__c) > '+MONTH(today_date)
      reviewCalendarList = (List<PACE_Review_Calendar__c>)rcList;
      
      continList = basecls.getObjectList('Contingency__c','Status__c = \'Open\' ','');
      contingencyList = (List<Contingency__c>)continList;
      
          getData();

}
public void getData()
{
        
/*
      List<sOBject> objList = new List<PACE_Program__c>();
      List<sObject> conList = new List<PACE_Concept__c>();
      List<sObject> liList = new List<Launch_Item__c>();
      List<sObject> rcList = new List<PACE_Review_Calendar__c>();
      List<sObject> continList = new List<Contingency__c>();
      
      Set<Id> progrmaidset = new Set<Id>();
      Set<Id> reviewCalendarset = new Set<Id>();
      List<PACE_Phase__c> phaseList= new List<PACE_Phase__c>();
            
      objList = basecls.getObjectList('PACE_Program__c','Status__c != \'Completed\' ','');
      List<PACE_Program__c> programList = (List<PACE_Program__c>)objList;
      
      conList = basecls.getObjectList('PACE_Concept__c','Status__c != \'Completed\' ','');
      List<PACE_Concept__c> conceptList = (List<PACE_Concept__c>)conList;
      
      liList = basecls.getObjectList('Launch_Item__c','Archive__c = False ','');
      List<Launch_Item__c> catalogUpdateList = (List<Launch_Item__c>)liList;
      
      rcList = basecls.getObjectList('PACE_Review_Calendar__c',format_date,''); //Review_Date__c >\''+today_date+'\'MONTH(Review_Date__c) > '+MONTH(today_date)
      List<PACE_Review_Calendar__c> reviewCalendarList = (List<PACE_Review_Calendar__c>)rcList;
      
      continList = basecls.getObjectList('Contingency__c','Status__c = \'Open\' ','');
      List<Contingency__c> contingencyList = (List<Contingency__c>)continList;
      
      */
      
      programMProgramList.clear();
     // programMConceptList.clear(); 
      programMcatalogUpdateList.clear();
      progrmMreviewCalendarList.clear();
      activeLaunchItemList.clear();
      launchItemApproval.clear();
        
      //Filter Programs based on filter criteria
      if((division=='all') && (productline == 'all'))
      {
              programMProgramList=programList.clone();
      }
      else 
      {
          for(PACE_Program__c pgmRecord : programList)
          {
              
              if((division=='all') && (pgmRecord.Product_Line__c==productline))
              {
                      programMProgramList.add(pgmRecord);
              }
              else if((productline=='all') && (pgmRecord.Division__c==division))
              {
                      programMProgramList.add(pgmRecord);
              }
              else if((pgmRecord.Division__c==division) && (pgmRecord.Product_Line__c==productline))
              {
                      programMProgramList.add(pgmRecord);
               }
          }
       }
      
      // Filter concepts based on filter criteria 
  /*    if((division_con=='all') && (productline_con == 'all'))
      {
              programMConceptList=conceptList.clone();
      }
      else 
      {
          for(PACE_Concept__c conRecord : conceptList)
          {
             
              if((productline_con=='all') && (conRecord.Division__c==division_con))
              {
                      programMConceptList.add(conRecord);
              }
              else if(division_con=='all') {
                    //  throw new customException("Product Line:"+productline+" Division: "+
                  if (conRecord.Product_Line__c==productline_con)
                  {
                          programMConceptList.add(conRecord);
                  }
              }
              else if((conRecord.Division__c==division_con) && (conRecord.Product_Line__c==productline_con))
              {
                      programMConceptList.add(conRecord);
               }
          }
       }
       
    */
      if(activation=='all') 
      {
        programMcatalogUpdateList=catalogUpdateList.clone();
      }
      else 
      {
          for(Launch_Item__c liRecord :catalogUpdateList)
          {
              if(liRecord.PLU__c==activation)
              {
                      programMcatalogUpdateList.add(liRecord);
              }
          }
       }

      
      
       progrmMreviewCalendarList.sort();

       progrmMcontingencyList=contingencyList.clone();
 
     
     for(Launch_Item__c liRecord :catalogUpdateList)
          {
                      activeLaunchItemList.add(liRecord);
          }
    
    /* Checking for the User ID and based on User ID decide if the User own any of these items Program,Concept or Catalog Update Item then
       retrieve the items which User owns and show them */
    for(PACE_Program__c pgmRecord : programList)
      {
        if(userId == pgmRecord.Program_Manager__c)
        {
            programManProgramList.add(pgmRecord);
            progrmaidset.add(pgmRecord.Id);
        }
        else if(userId == pgmRecord.Product_Manager__c )
        {
            programManProgramList.add(pgmRecord);
            progrmaidset.add(pgmRecord.Id);
        }
          
      }
      
     
      for(PACE_Phase__c phaseRecord : [Select Id,Name,SIR_Meeting_Date__c,PRB_Review_Date__c,Exception_Review_Date__c,Contingency__c  From PACE_Phase__c Where PACE_Program__c IN :progrmaidset ])
      {
        phaseList.add(phaseRecord);
      }
     
     
      Set<PACE_Review_Calendar__c> rcShowSet = new Set<PACE_Review_Calendar__c>();
      for(PACE_Phase__c phaserc : phaseList)
      {
        for(PACE_Review_Calendar__c prc : reviewCalendarList)
        {
            if(phaserc.SIR_Meeting_Date__c == prc.Id || phaserc.PRB_Review_Date__c == prc.Id || phaserc.Exception_Review_Date__c == prc.Id)
            {
              rcShowSet.add(prc);
            }
        }
        
      }
      
      
      for(PACE_Phase__c phaserc : phaseList)
      {
        for(Contingency__c con : contingencyList)
        {
            if(con.Phase__c==phaserc.Id)
            {
              myContingenctList.add(con);
            }
        }
        
      }
      
      
    /*  
      for(PACE_Concept__c conRecord : conceptList)
      {
        if(userId == conRecord.Program_Manager__c)
        {
            programManConceptList.add(conRecord);            
        }
        else if(userId == conRecord.Product_Manager__c )
        {
            programManConceptList.add(conRecord);
        }  
      }  
      
      for(PACE_Concept__c conceptrc : conceptList)
      {
        for(PACE_Review_Calendar__c prc : reviewCalendarList)
        {
           if(conceptrc.Concept_PRB_Review_Date__c == prc.Id)
            {
              rcShowSet.add(prc);
            }
            
        }
        
      }
      
      
      */
      if(!rcShowSet.isEmpty())
      {
        rcShowList.addAll(rcShowSet);
      }
   /*
      for(PACE_Concept__c conceptrc : conceptList)
      {
        for(Contingency__c con : contingencyList)
        {  
            if(con.Concept__c==conceptrc.Id){
                myContingenctList.add(con);
             }
                
        }
        
      }
    */
      
      for(Launch_Item__c conRecord : catalogUpdateList)
      {
        if(userId == conRecord.Product_Manager__c )
        {
            productMancatalogUpdateList.add(conRecord);
        }  
      }
      
      for(Launch_Item__c activerecord : productMancatalogUpdateList)
      {
         
                   activemyLaunchItemList.add(activerecord);
      
      }
      
      
     
      if(reviewmonth=='all') 
      {
      progrmMreviewCalendarList=reviewCalendarList.clone();
      }
      else if(reviewmonth=='myvents')
      {
          if(!rcShowSet.isEmpty())
          {
            progrmMreviewCalendarList.addAll(rcShowSet);
          }
                

      }
      else 
      {
          for(PACE_Review_Calendar__c rcRecord :reviewCalendarList)
          {
              if(rcRecord.Review_Month__c==reviewmonth)
              {
                      progrmMreviewCalendarList.add(rcRecord);
              }
          }
       }
       

      if((programManProgramList != NULL && programManProgramList.size() > 0 ) || (productMancatalogUpdateList != NULL && productMancatalogUpdateList.size() > 0))
        {
            isUserProfilePM =true;
        }  
}
      

}