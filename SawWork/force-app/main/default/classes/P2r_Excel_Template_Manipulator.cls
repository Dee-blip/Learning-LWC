/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 29/08/2020

Base Line : Used as a pert of dynamic Excel Generation feature for CPQ/HD

Purpose : To get the data for dynamic section generation

Usage : used as an implementation for P2r_excel_template_manipulator.

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

component Associated : [ P2r_excel_template_manipulator ]
Class used : NONE

*/

public with sharing class P2r_Excel_Template_Manipulator {
@AuraEnabled
//public List<sObject> sobjListResult = new List<sObject>();
public String response = '{}';
 
//getting dynamic query
private Map<String,List<CPQ_QuoteLineWrapper>> getDynamicSectionData(String recordId){      
    //List<sObject> sobjList = Database.query(query);
    Map<String, List<CPQ_QuoteLineWrapper>> quoteLineData = new Map<String, List<CPQ_QuoteLineWrapper>>();

    CPQ_QuoteWrapper quoteData =  new CPQ_QuoteFactory(recordId).generateQuoteData();
    //System.debug(JSON.serialize(quoteData));

    List<CPQ_QuoteLineWrapper> quoteLines  = new List<CPQ_QuoteLineWrapper>();

    for(CPQ_QuoteLineWrapper item : quoteData.productLines){
        List<CPQ_QuoteLineWrapper> periodLines = new List<CPQ_QuoteLineWrapper>();
        periodLines.addAll(item.periodCommitLines);
        item.periodCommitLines.clear();
        List<CPQ_QuoteLineWrapper> otherLines = new List<CPQ_QuoteLineWrapper>();
        otherLines.addAll(item.quoteLines);
        item.quoteLines.clear();

        quoteLines.add(item);

        if(!periodLines.isEmpty()){
            quoteLines.addAll(periodLines);
        }
        if(!otherLines.isEmpty()){
            quoteLines.addAll(otherLines);
            
        }
        
    }

    //setting the name of the integration product to the line
    for(CPQ_QuoteLineWrapper item : quoteData.integrationLines){
        item.name = item.productCode;
        quoteLines.add(item);
    }

    quoteLineData.put('quoteLines', quoteLines);

    // System.debug(JSON.serialize(quoteLineData));
    
    return  quoteLineData;
}

@AuraEnabled(cacheable=true)
public static P2r_Excel_Template_Manipulator classObject(String recordId){
    P2r_Excel_Template_Manipulator obj = new P2r_Excel_Template_Manipulator();
    obj.response = JSON.serialize(obj.getDynamicSectionData(recordId));
    return obj;
}//

}//Class