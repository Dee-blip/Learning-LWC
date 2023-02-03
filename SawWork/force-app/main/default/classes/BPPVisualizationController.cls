public with sharing class BPPVisualizationController {

    public Lead leadObj {get;set;}
    private ApexPages.StandardController sc;
    public List<GraphData> barGraphData {get;set;}
    public List<selectOption> perfOptions {get;set;}
    public List<selectOption> growthOptions {get;set;}
    public List<selectOption> secOptions {get;set;}
    public List<selectOption> costOptions {get;set;}
    public List<selectOption> uxOptions {get;set;}

    public Map<String,Boolean> enabledPicklist {get;set;}
    public String BUOpt{get;set;}
    public PageReference redirectUrl{get;set;}
    public Boolean refreshPage {get; set;}
    public Boolean isRecordtypeakamai {get;set;}
    public Boolean editing {get; set;}

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public BPPVisualizationController(ApexPages.StandardController stdController) {
        sc=stdController;
        this.leadObj = (Lead)sc.getRecord();
        refreshPage=false;
        editing=false;
        isRecordtypeakamai = false;
        Map<String,String> bppStageValues = new Map<String,String>();
        bppStageValues.put('adg_Lead_Qual_Stg_Performance__c','Performance');
        bppStageValues.put('adg_Lead_Qual_Stg_Growth__c','Growth');
        bppStageValues.put('adg_Lead_Qual_Stg_Security__c','Security');
        bppStageValues.put('adg_Lead_Qual_Stg_Cost__c','Cost');
        bppStageValues.put('adg_Lead_Qual_Stg_UX__c','UX');
        List<String> qualstages = new List<String>();
        qualstages.addAll(bppStageValues.keySet());
        String leadid = leadObj.id;
        //SFDC-5166
        String query = 'select id,'+String.join(qualstages,',')+' ,adg_Status_Growth__c,adg_Status_Cost__c,adg_Status_Performance__c,adg_Status_Security__c,adg_Status_UX__c,Product_Line__c,Recordtype.name,adg_Self_Generated_Lead_Type__c from lead where id=:leadid';
        this.leadObj = Database.query(query);
        if(leadObj.Recordtype.name=='Akamai Lead')
            isRecordtypeakamai = true;
        //leadObj = ld;
        populateGraphData(leadObj,bppStageValues);
        populateStatusForSDR();
        enablePicklist(leadObj,bppStageValues);

    }

    //Wrapper Class for Graph Data
        public class GraphData 
        {
            public String att {get;set;}
            public String E {get;set;}
            public String QE {get;set;}
            public String QL {get;set;}
            public String O {get;set;}
            public String Letter {get;set;}
            public GraphData(String att,String E, String QE, String QL,String O, String Letter) {
                this.att = att;
                this.E = E;
                this.QE = QE;
                this.QL = QL;
                this.O = O;
                this.Letter = Letter;
            }
        }
    private void populateGraphData(Lead ld,Map<String,String> bppStageValues){
        barGraphData = new List<GraphData>(); 
        
        for(String bppStageValue: bppStageValues.keySet()){
            String stageVal = (String)ld.get(bppStageValue);
            GraphData gd;
            if(getBarLength(stageVal)==0)
                gd = new GraphData(bppStageValues.get(bppStageValue),'#FFFFFF','#FFFFFF','#FFFFFF','#FFFFFF',getLetter(stageVal));
            if(getBarLength(stageVal)==25)
                gd= new GraphData(bppStageValues.get(bppStageValue),getBarColor(stageVal),'#FFFFFF','#FFFFFF','#FFFFFF',getLetter(stageVal));
            if(getBarLength(stageVal)==50)
                gd= new GraphData(bppStageValues.get(bppStageValue),getBarColor(stageVal),getBarColor(stageVal),'#FFFFFF','#FFFFFF',getLetter(stageVal));
            if(getBarLength(stageVal)==75)
                gd= new GraphData(bppStageValues.get(bppStageValue),getBarColor(stageVal),getBarColor(stageVal),getBarColor(stageVal),'#FFFFFF',getLetter(stageVal));
            if(getBarLength(stageVal)==100)
                gd= new GraphData(bppStageValues.get(bppStageValue),getBarColor(stageVal),getBarColor(stageVal),getBarColor(stageVal),getBarColor(stageVal),getLetter(stageVal));
            barGraphData.add(gd);
        }
        system.debug(LoggingLevel.ERROR,'barGraphData:: '+barGraphData);
    }

    private Integer getBarLength(String stageVal){
        Integer barLen = (stageVal== 'Prospect'?0:(stageVal=='Engaged'?25:(stageVal == 'Qualified Engaged'?50:(stageVal == 'Qualified Lead - Warm'||stageVal == 'Qualified Lead - Hot'||stageVal == 'Closed'||stageVal == 'Turnback'?75:(stageVal == 'Opportunity Created'||stageVal == 'Closed Lost'||stageVal == 'Closed Won'?100:0)))));
        return barLen;
    }

    private String getLetter(String stageVal){
        String barLabel = (stageVal == 'Qualified Lead - Hot'? 'Hot' : (stageVal == 'Closed'? 'C' :(stageVal == 'Turnback'?'T':(stageVal == 'Opportunity Created'? '1' : (stageVal == 'Closed Lost' ? 'L' : (stageVal == 'Closed Won'?'W':''))))));
        return barLabel;
    }


    private String getBarColor(String stageVal){
        String barCol = (stageVal== 'Engaged'||stageVal=='Qualified Engaged'||stageVal=='Turnback'|| stageVal == 'Closed' ||stageVal=='Closed Lost' ?'#999ea8': ( stageVal == 'Qualified Lead - Hot' || stageVal == 'Qualified Lead - Warm' ||stageVal== 'Opportunity Created' ?'#2d9e31':(stageVal == 'Closed Won'?'#1b55c1':'#C6EFF7')));
        return barCol;
    }
    private void enablePicklist(Lead ld,Map<String,String> bppStageValues){
        enabledPicklist = new Map<String,Boolean>();
        for(String bpp : bppStageValues.keySet()){
            String stageVal = (String)ld.get(bpp);
            enabledPicklist.put(bppStageValues.get(bpp),false);
            if(stageVal=='Qualified Lead - Warm' || stageVal=='Qualified Lead - Hot')
                enabledPicklist.put(bppStageValues.get(bpp),true);
        }
    }

    public void populateStatusForSDR() {
        List<selectOption> allOptions = GSMUtilClass.getDynamicPicklist('object','Lead','adg_Status_Performance__c',null);    
        perfOptions = new List<SelectOption>();
        growthOptions = new List<SelectOption>();
        secOptions = new List<SelectOption>();
        costOptions = new List<SelectOption>();
        uxOptions = new List<SelectOption>();
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption('--', '--'));
        
        for(selectOption opt: allOptions){
            SelectOption option = new SelectOption(opt.getValue(), opt.getLabel());    
                if(leadObj.adg_Status_Performance__c!=null && opt.getValue().equalsIgnoreCase(leadObj.adg_Status_Performance__c))
                    perfOptions.add(new SelectOption(opt.getValue(), opt.getLabel()));
                if(leadObj.adg_Status_Growth__c!=null && opt.getValue().equalsIgnoreCase(leadObj.adg_Status_Growth__c))    
                    growthOptions.add(new SelectOption(opt.getValue(), opt.getLabel()));
                if(leadObj.adg_Status_Security__c!=null && opt.getValue().equalsIgnoreCase(leadObj.adg_Status_Security__c))
                    secOptions.add(new SelectOption(opt.getValue(), opt.getLabel()));
                if(leadObj.adg_Status_Cost__c!=null && opt.getValue().equalsIgnoreCase(leadObj.adg_Status_Cost__c))
                    costOptions.add(new SelectOption(opt.getValue(), opt.getLabel()));
                if(leadObj.adg_Status_UX__c!=null && opt.getValue().equalsIgnoreCase(leadObj.adg_Status_UX__c))
                    uxOptions.add(new SelectOption(opt.getValue(), opt.getLabel()));
           
            if(opt.getValue().containsIgnoreCase('Turnback')||opt.getValue().containsIgnoreCase('Closed')||opt.getValue().containsIgnoreCase('Converted')){ //
                if(!option.getValue().equalsIgnoreCase(leadObj.adg_Status_Performance__c))
                    perfOptions.add(option);
                if(!option.getValue().equalsIgnoreCase(leadObj.adg_Status_Growth__c))
                    growthOptions.add(option);
                if(!option.getValue().equalsIgnoreCase(leadObj.adg_Status_Security__c))
                    secOptions.add(option);
                if(!option.getValue().equalsIgnoreCase(leadObj.adg_Status_Cost__c))
                    costOptions.add(option);
                if(!option.getValue().equalsIgnoreCase(leadObj.adg_Status_UX__c))
                    uxOptions.add(option);
                //options.add(new SelectOption(opt.getLabel(), opt.getValue())); //
            }
            //options.add(opt);
        }
     }
    public PageReference SaveLead() {

        redirecturl = new PageReference('/'+leadObj.id);
        refreshPage=true;
        ApexPages.getMessages().clear();
        system.debug(LoggingLevel.ERROR,'leadObj:: '+leadObj+' : '+leadObj.adg_Status_Performance__c);
        List<Lead> recordsToBeUpdated = new List<Lead>{leadObj};    
        Database.SaveResult[] saveRes = Database.Update(recordsToBeUpdated , false);
           List<Error_Log__c> errorLogs = new List<Error_Log__c>();

           Integer count = 0;
           for(Database.SaveResult result : saveres)
           {
               if(!result.isSuccess()){
                   String errMessage = '';
                   for(Database.Error err : result.getErrors())
                   {
                       if(!err.getFields().isEmpty())
                          // errMessage += '<b>•</b> &nbsp;&nbsp;' + String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '<br/>';
                          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.join(err.getFields(), ' AND ') +': ' + err.getMessage()));
                       else
                          // errMessage += '<b>•</b> &nbsp;&nbsp;' + err.getMessage() + '<br/>';
                          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
                   }
                   Map<String, Object> fieldsToValue = recordsToBeUpdated[count].getPopulatedFieldsAsMap();
                   String objectState = JSON.serialize(fieldsToValue);

                   Error_Log__c el = new Error_Log__c(Name='SaveLead', Class__c='BPPVisualizationController', Error_Message__c=errMessage , Object_State__c=objectState);
                   System.debug(LoggingLevel.Error, ' errored insert'+el);
                   errorLogs.add(el);
                   // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMessage));
                   refreshPage=false;
               }
               count += 1;
           }
           if(!refreshPage)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please correct the above errors and click on "Update C2A" button to continue.'));
           else
            editing = false;
           System.Debug(LoggingLevel.Error, ' errorlogs'+errorlogs);
           if(errorLogs.size()>0)
               Database.insert(errorLogs, false);
        //sc.save();
        return null;
    }
    
    public PageReference OnCancel() {
        redirecturl = new PageReference('/'+leadObj.id);
        refreshPage=true;
        return null;
    } 

    public void OnEdit() {
         editing = true;
    }    
}