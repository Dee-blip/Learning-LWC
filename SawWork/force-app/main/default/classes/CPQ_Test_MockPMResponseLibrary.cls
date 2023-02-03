/**
* This class is used to create the mock responses for PM API calls
* @author  Shashank Hegade 
* @version 1.0
* @since   2021-08-04
*/

@isTest
public class CPQ_Test_MockPMResponseLibrary implements HttpCalloutMock {
    
    public final String sectionResponse;
    public final String attributeRespose;
    public final String pricingRespose;
    public final String failureRespose;
    public final String literatureResponse;
    public final String productResponse;

    public CPQ_Test_MockPMResponseLibrary(){
        this.sectionResponse = CPQSettings.getMetadataValue('mockSectionResponse');
        this.attributeRespose = CPQSettings.getMetadataValue('mockAttributeResponse');
        this.pricingRespose = CPQSettings.getMetadataValue('mockPricingResponse');
        this.literatureResponse = CPQSettings.getMetadataValue('mockLiteratureResponse');
        this.productResponse= CPQSettings.getMetadataValue('mockingProductResponse');
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