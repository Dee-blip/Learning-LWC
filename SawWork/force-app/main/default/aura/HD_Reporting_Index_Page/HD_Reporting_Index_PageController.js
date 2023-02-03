({
    doInit : function(cmp, event, helper) {
        //setting today date by default
        var today = new Date();

        var month=(today.getMonth() + 1);
        if((today.getMonth()+1)<10){
            month="0"+(today.getMonth() + 1);
        }

        var date=today.getDate();
        if((today.getDate())<10){
            date="0"+(today.getDate());
        }
        cmp.set('v.to', today.getFullYear() + "-" +month+ "-" +date);
        
    },
    handleSelectChangeEvent : function(cmp, event) {
        var tempMap = event.getParam("selectedOptions");

        var type=tempMap.key;
        var values=[];
        
        var selectedValues=tempMap.values;

        if(type=="serviceRequestSelected"){
            cmp.set("v.selectedServiceRequests",selectedValues);
        }else if(type=="statusSelected"){
            cmp.set("v.selectedStatus",selectedValues);
        }
        
    },
    handleViewReportClick : function (cmp, event, helper) {
        cmp.set("v.isSpinnerActive",true);
        var selectedServiceRequests=cmp.get("v.selectedServiceRequests");
        var selectedStatus=cmp.get("v.selectedStatus");

        var from=cmp.get("v.from");
        var to=cmp.get("v.to");
        
        if(selectedServiceRequests === undefined || selectedServiceRequests === null || selectedServiceRequests.length<1){
            helper.showWarningToast(cmp, event, helper,"Please select any Service Request");
            cmp.set("v.isSpinnerActive",false);
        }else if(from === undefined || from === null){
            helper.showWarningToast(cmp, event, helper,"Please select FROM Date");
            cmp.set("v.isSpinnerActive",false);
        }else if(to === undefined || to === null){
            helper.showWarningToast(cmp, event, helper,"Please select TO Date");
            cmp.set("v.isSpinnerActive",false);
        }else{

        var response;
        var action = cmp.get("c.getServiceRequestReport"); //getServiceRequestReport
        action.setParams({
            "requestDefinationsList" : selectedServiceRequests,
            "selectedStatus" : selectedStatus,
            "fromDate" : from,
            "toDate" : to
        });
        //var values=[];
        
        action.setCallback(this,function(data){
             

             response = data.getReturnValue();

             if(response && response.length > 0){

             var report=response[0];
             if(report!=""){
                cmp.set("v.isReportAvailable",true);
                cmp.set("v.report",report);
             }

             report=response[1];
             if(report!=""){
                cmp.set("v.isSpinnerActive",false);
                cmp.set("v.isCsvReportAvailable",true);
                cmp.set("v.reportInCsvFormat",report);
             }
         }
             else{
                cmp.set("v.isSpinnerActive",false);
                helper.showWarningToast(cmp, event, helper,"No record to display!");
             }

        });

        $A.enqueueAction(action);
    }
        
    },

    downloadServiceReportAsCsv:function(cmp, evt, helper) {

        var csv = cmp.get("v.reportInCsvFormat");
        if (csv == null){return;} 
        
        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####     
         var hiddenElement = document.createElement('a');
          hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
          hiddenElement.target = '_self'; // 
          hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv] 
          document.body.appendChild(hiddenElement); // Required for FireFox browser
          hiddenElement.click(); // using click() js function to download csv file
        
    },
    
    incidentViewSelected: function(cmp, evt, helper) {
        cmp.set("v.isReportTypeIncident",true);
        cmp.set("v.isReportTypeServiceRequest",false);
        helper.showErrorToast(cmp,evt,helper,"Incident Type View is Not Implemented Yet");
    },
    serviceRequestViewSelected: function(cmp, evt, helper) {
        cmp.set("v.isReportTypeIncident",false);
        cmp.set("v.isReportTypeServiceRequest",true);
    },
    handleMouseLeave: function(cmp, event, helper) {
        var selectedServiceRequests=cmp.get("v.selectedServiceRequests");
        var from=cmp.get("v.from");
        var to=cmp.get("v.to");
        console.log("Inside handleMouseLeave: "+"selectedServiceRequests:"+selectedServiceRequests+", from:"+from+", "+to);
    if(selectedServiceRequests&&from&&to){
        cmp.set("v.isViewReportButtonDisabled",false);
    }else{
        cmp.set("v.isViewReportButtonDisabled",true);
    }
  }
})