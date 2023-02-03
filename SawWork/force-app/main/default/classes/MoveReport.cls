public with sharing class MoveReport {
    public static void createObject()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
	    service.SessionHeader = new MetadataService.SessionHeader_element();
	    service.SessionHeader.sessionId = UserInfo.getSessionId();
        MetadataService.CustomObject customObject = new MetadataService.CustomObject();
        customObject.fullName = 'TestReports__c';
        customObject.label = 'Test';
        customObject.pluralLabel = 'Tests';
        customObject.nameField = new MetadataService.CustomField();
        customObject.nameField.type_x = 'Text';
        customObject.nameField.label = 'Test Record';
        customObject.deploymentStatus = 'Deployed';
        customObject.sharingModel = 'ReadWrite';
        List<MetadataService.SaveResult> results =
            service.createMetadata(
                new MetadataService.Metadata[] { customObject });
        handleSaveResults(results[0]);
    }

    public static void moveReportToAnotherFolder(String sFolderApiName, String sReportApiName, String tFolderApiName) {
	    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
	    service.SessionHeader = new MetadataService.SessionHeader_element();
	    service.SessionHeader.sessionId = UserInfo.getSessionId();
	
	    // Create the report clone
	    //List<MetadataService.SaveResult> results = service.createMetadata(new MetadataService.Metadata[] { apexReport });
	
	    // Get the report to move
	    MetadataService.Report reportToMove = (MetadataService.Report) service.readMetadata('Report', new String[] { sFolderApiName+'/'+sReportApiName }).getRecords()[0];
        // System.debug('report folder name'+reportToMove.folderName);
	    reportToMove.fullName = tFolderApiName + '/' + sReportApiName;
        reportToMove.folderName = tFolderApiName;

        // // Instanciate a new one to attribute the same metadata from the report to clone
	    // MetadataService.Report apexReport = new MetadataService.Report();
	    // // Set the cloned report properties from parameters and the source report
	    // apexReport.name = reportToClone.name + ' Clone';
	    // apexReport.fullName = tFolderApiName + '/' + tReportApiName;
	    // apexReport.reportType = reportToClone.reportType;
	    // apexReport.description = reportToClone.description;
	    // apexReport.format = reportToClone.format;
	    // apexReport.filter = reportToClone.filter;
	    // apexReport.showDetails = reportToClone.showDetails;
	    // apexReport.sortColumn = reportToClone.sortColumn;
	    // apexReport.sortOrder = reportToClone.sortOrder;
	    // apexReport.groupingsAcross = reportToClone.groupingsAcross;
	    // apexReport.groupingsDown = reportToClone.groupingsDown;
	    // apexReport.chart = reportToClone.chart;
	    // apexReport.timeFrameFilter = reportToClone.timeFrameFilter;
	    // apexReport.columns = reportToClone.columns;
	
	    // // Update the report 
	    List<MetadataService.SaveResult> results = service.updateMetadata(new MetadataService.Metadata[] { reportToMove });
        // List<MetadataService.SaveResult> results2 = service.deleteMetadata(new MetadataService.Metadata[] { reportToClone });
	
	    // Handle results
	    handleSaveResults(results[0]);
        //handleSaveResults(results2[0]);
	}

    public static void deleteReport(String sReportApiName) {
	    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
	    service.SessionHeader = new MetadataService.SessionHeader_element();
	    service.SessionHeader.sessionId = UserInfo.getSessionId();
	
	
	    // Delete the report 
	    List<MetadataService.DeleteResult> results =
            service.deleteMetadata(
                'Report', new String[] { sReportApiName });
        handleDeleteResults(results[0]);
	}

    static void handleSaveResults(MetadataService.SaveResult saveResult)
    {
        // Nothing to see?
        if(saveResult==null || saveResult.success)
            return;
        // Construct error message and throw an exception
        if(saveResult.errors!=null)
        {
            List<String> messages = new List<String>();
            messages.add(
                (saveResult.errors.size()==1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0)
                System.debug('Error with'+messages);
        }
        if(!saveResult.success)
            System.debug('Request failed with no specified error');
    }

    public static void handleDeleteResults(MetadataService.DeleteResult deleteResult)
    {
        // Nothing to see?
        if(deleteResult==null || deleteResult.success)
            return;
        // Construct error message and throw an exception
        if(deleteResult.errors!=null)
        {
            List<String> messages = new List<String>();
            messages.add(
                (deleteResult.errors.size()==1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + deleteResult.fullName + '.');
            for(MetadataService.Error error : deleteResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0)
                System.debug('Exception with'+messages);
        }
        if(!deleteResult.success)
            System.debug('Exception without message');
    }
}