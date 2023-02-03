@isTest
public class SObjectBuilder
{
	final List<SObject> records;
    final List<Id> recordIds;
	final SObjectType sObjectType;
	final Map<SObjectField, Object> fieldToValue;

	Integer count;

	public SObjectBuilder(SObjectType sObjectType)
	{
		this.count = 1;
		this.sObjectType = sObjectType;
		this.records = new List<SObject>();
		this.fieldToValue = new Map<SObjectField, Object>();
        this.recordIds = new List<Id>();
	}

    public SObjectBuilder eagerPopulate()
    {
        fieldToValue.putAll(RequiredFieldsCache.get(sObjectType));
        return this;
    }

	public SObjectBuilder count(Integer count)
	{
		this.count = count;
		return this;
	}

    public SObjectBuilder put(SObjectField field, List<SObject> values)
    {
        this.fieldToValue.put(field, new SObjectFieldProviders.IteratingFieldProvider(values));
        return this;
    }
    
    public SObjectBuilder put(SObjectField field, List<String> values)
    {
        this.fieldToValue.put(field, new SObjectFieldProviders.StringListProvider(values));
        return this;
    }

	public SObjectBuilder put(SObjectField field, Object value)
	{
		this.fieldToValue.put(field, value);
		return this;
	}

    public SobjectBuilder nullify(SObjectField field)
    {
        if(fieldToValue.containsKey(field))
            fieldToValue.remove(field);
        return this;
    }

	public SObjectBuilder putAll(Map<SObjectField, Object> fieldToValue)
	{
		this.fieldToValue.putAll(fieldToValue);
		return this;
	}
	public SObjectBuilder provideDummyIds()
	{
		SObjectField idField = this.sObjectType.getDescribe().fields.getMap().get('id');
		this.put(idField, SObjectFactory.provideDummyId(this.sObjectType));
		return this;
	}

    public SObjectBuilder updateAll()
    {
        for(Sobject sob : this.records)
        {
            for(SobjectField sobf : fieldToValue.keySet())
            {
                    Object value = fieldToValue.get(sobf);
                    if (value instanceOf IFieldProvider)
                        value = ((IFieldProvider)value).getValue();
                sob.put(sobf, value);
            }
        }
        
        update this.records;
        return this;
    }

	public SObjectBuilder build()
	{
		this.records.clear();
		this.records.addAll(SObjectFactory.build(sObjectType, count, fieldToValue));
        this.recordIds.addAll(pluckIds(records));
		return this;
	}
	public SObjectBuilder create()
	{
		this.records.clear();
		this.records.addAll(SObjectFactory.create(sObjectType, count, fieldToValue));
        this.recordIds.addAll(pluckIds(records));
		return this;
	}
	public SObjectBuilder createAsAdmin()
	{
		system.runAs(SObjectFactory.ADMIN_USER) { this.create(); }
		return this;
	}

    public List<SObject> refreshRecords()
    { 
        return SObjectRepository.get(fieldToValue.keySet(), recordIds) ;   
    }

    public SObject refreshRecord()
    {
        return refreshRecords().get(0);
    }

	public SObject getRecord() { return this.records[0]; }
	public List<SObject> getRecords() { return this.records; }

    private Set<Id> pluckIds(List<Sobject> records)
    {
        Map<Id, SObject> recordMap = new Map<Id, SObject>();
        recordMap.putAll(records);
        return recordMap.keySet();
    }
}