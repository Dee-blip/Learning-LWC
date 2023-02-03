/**
 * Interface containing methods Trigger Handlers must implement to enforce best practice
 * and bulkification of triggers.
 */
public abstract class ITrigger {
	/**
	 * bulkBefore
	 *
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		
	}
	
	/**
	 * bulkAfter
	 *
	 * This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		
	}
	
	/**
	 * beforeInsert
	 *
	 * This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public abstract void beforeInsert(List<SObject> so);
	public void executeBeforeInsert(List<SObject> so) {
		beforeInsert(so);
	}
	
	/**
	 * beforeUpdate
	 *
	 * This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public abstract void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so);
	public void executeBeforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
		beforeUpdate(oldSo, so);
	}

	/**
	 * beforeDelete
	 *
	 * This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public abstract void beforeDelete(Map<Id, SObject> so);
	public void executeBeforeDelete(Map<Id, SObject> so) {
		beforeDelete(so);
	}

	/**
	 * afterInsert
	 *
	 * This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public abstract void afterInsert(Map<Id, SObject> so);
	public void executeAfterInsert(Map<Id, SObject> so) {
		afterInsert(so);
	}

	/**
	 * afterUpdate
	 *
	 * This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public abstract void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so);
	public void executeAfterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
		afterUpdate(oldSo, so);
	}

	/**
	 * afterDelete
	 *
	 * This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public abstract void afterDelete(Map<Id, SObject> so);
	public void executeAfterDelete(Map<Id, SObject> so) {
		afterDelete(so);
	}

	/**
	 * andFinally
	 *
	 * This method is called once all records have been processed by the trigger. Use this 
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		
	}
}