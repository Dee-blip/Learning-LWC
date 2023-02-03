public interface ApexTriggerInterface {

	void startTrigger(String sobjType); 

	void beforeInsertBeforeUpdateTrigger();

	void beforeDeleteBeforeUndeleteTrigger();

	void afterInsertAfterUpdateTrigger();

	void afterDeleteAfterUndeleteTrigger();
}