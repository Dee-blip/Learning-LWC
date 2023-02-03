@isTest
public with sharing class CPQ_Test_MockPMResponseLibraryCarrier implements HttpCalloutMock {
    public final String sectionResponse;
    public final String attributeRespose;
    public final String pricingRespose;
    public final String failureRespose;
    public final String literatureResponse;
    public final String productResponse;

    public CPQ_Test_MockPMResponseLibraryCarrier(){
        this.sectionResponse = CPQSettings.getMetadataValue('mockSectionResponseCarrier');
        this.attributeRespose = CPQSettings.getMetadataValue('mockAttributeResponseCarrier');
        this.pricingRespose = CPQSettings.getMetadataValue('mockPricingResponseCarrier');
        this.literatureResponse = CPQSettings.getMetadataValue('mockLiteratureResponseCarrier');
        this.productResponse= CPQSettings.getMetadataValue('mockingProductResponseCarrier');
        this.failureRespose = '{"status":"400"}';
    }

    public HTTPResponse respond(HTTPRequest req) {
        
        String endpoint = req.getEndpoint();
        String requestType = req.getMethod();

        HttpResponse res = new HttpResponse();

        //mock attribute request
        if(endpoint.contains('sections') && requestType == 'GET'){

            res.setHeader('Content-Type', 'application/json');
            res.setBody(sectionResponse);
            res.setStatusCode(200);
            return res;
            
        }

        // mock pricing request
        if( endpoint.contains('pricing') && requestType == 'GET'){

            res.setHeader('Content-Type', 'application/json');
            res.setBody(pricingRespose);
            res.setStatusCode(200);
            return res;

        }

        // mock attribute response
        if( endpoint.contains('attribute') && requestType == 'GET'){

            res.setHeader('Content-Type', 'application/json');
            res.setBody(attributeRespose);
            res.setStatusCode(200);
            return res;
        }

        // mock literature response 
        if( endpoint.contains('literature') && requestType == 'GET'){

            res.setHeader('Content-Type', 'application/json');
            res.setBody(literatureResponse);
            res.setStatusCode(200);
            return res;
        }
        if( requestType == 'POST'){

            res.setHeader('Content-Type', 'application/json');
            res.setBody(productResponse);
            res.setStatusCode(200);
            return res;
        }


        res.setHeader('Content-Type', 'application/json');
        res.setBody(failureRespose);
        res.setStatusCode(400);
        return res;
    
        
    }  
}