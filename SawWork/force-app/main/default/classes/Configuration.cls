public class Configuration {

	private Map<String, Configuration__c> settings;
	public Application_Settings__c orgSetting {get; set;}
	private Map<String, ObjectAssociationSettings__c> associationSettings;
	
	private static Configuration instance;

	public Configuration() {
		settings = Configuration__c.getAll();
		orgSetting = Application_Settings__c.getAll().get('OrgSetting');
		if (orgSetting == null) {
			orgSetting = new Application_Settings__c(Name = 'OrgSetting', Enable_Account_Hierarchy_Sharing__c = true);
		}
		associationSettings = ObjectAssociationSettings__c.getAll();
	}
	
	public static Configuration getInstance() {
		if (instance == null) {
			instance = new Configuration();
		}
		return instance;
	}
	
	public List<ObjectAssociationSettings__c> getAssociationSettings() {
		return associationSettings.values();
	}
	
	/** Object Associations**/
	public String getObjectAccessLevel(String objectName) {
		ObjectAssociationSettings__c s = associationSettings.get(objectName);
		if (s == null) {
			s = createDefaultSettings(objectName);
		}

		return (s.Access_Level__c == null || s.Portal_Role__c == null) ? 'None' : s.Access_Level__c;
	}
	
	public String getPortalRole(String objectName) {
		ObjectAssociationSettings__c s = associationSettings.get(objectName);
		if (s == null) {
			s = createDefaultSettings(objectName);
		}
		return (s.Portal_Role__c == null) ? 'None' : s.Portal_Role__c;
	}
	/***End Object Associations**/
	
	public Boolean getShareWithAccount(String objectName) {
		Configuration__c config = settings.get(objectName);
		return (config == null) ? false : config.Share_with_this_Account__c;
	}
	
	public Set<String> getCustomFields(String objectName) {
		Configuration__c config = settings.get(objectName);
		Set<String> customFields = new Set<String>();
	
		if (config != null) {
			for(String fieldName : config.Field_Name__c.split(',')) {
				customFields.add(fieldName.trim());
			}
		}
		return customFields;
	}
	
	public Boolean isAccountHierarchyEnabled() {
		return (orgSetting == null) ? true : orgSetting.Enable_Account_Hierarchy_Sharing__c;		
	}
	
	private ObjectAssociationSettings__c createDefaultSettings(String objectName) {
		ObjectAssociationSettings__c s = new ObjectAssociationSettings__c(Name = objectName, Access_Level__c = 'Read', Portal_Role__c = 'Partner');
		insert s;
		associationSettings = ObjectAssociationSettings__c.getAll();
		return s;
	}
	
	//constants
	public final static String ACCOUNT = 'Account';
	public final static String LEAD = 'Lead';
	public final static String OPPORTUNITY = 'Opportunity';
	
	public final static String ACCESS_NONE = 'None';
	public final static String ACCESS_READ = 'Read';
	public final static String ACCESS_EDIT = 'Edit';
}