/**
 * Interface containing methods Partnet Handlers must implement to ensure proper handling of all 
 * proper handling of all use cases.
 */
public interface IPartnerProcessor {
    /**
	 * inboundRequestProcessor
	 *
	 * This method is called iteratively for processing the Inbound
	 * request from any partner.
	 */
	void inboundRequestInsertProcessor(List<SObject> lSobject, Boolean isBefore);
    
    void inboundRequestUpdateProcessor(List<SObject> lSobjectNew, Boolean isBefore, List<SObject> lSobjectOld);
    
    /**
	 * outboundRequestProcessor
	 *
	 * This method is called iteratively for processing the Outbound
	 * request from any partner..
	 */
    void outboundRequestInsertProcessor(List<SObject> lSobject, Boolean isBefore);
    
    void outboundRequestUpdateProcessor(List<SObject> lSobjectNew, Boolean isBefore, List<SObject> lSobjectOld);
    
    //void insertProcessedRecords();
}