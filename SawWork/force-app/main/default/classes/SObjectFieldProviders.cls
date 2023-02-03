@isTest
public class SObjectFieldProviders
{
    private static final String TEST_USER_PREFIX = 'akmtt';
    private static final String TEST_website_PREFIX = 'www.akmtt';
    private static final String CHANNEL_MAPPING_NAME_PREFIX= 'tstch';
    public class CountException extends Exception { }
    public class EmptyQueryException extends Exception { }
    
    public class UniqueNumberProvider implements IFieldProvider
    {
        Integer counter;
        public UniqueNumberProvider() { this(0); }
        public UniqueNumberProvider(Integer start)
        {
            this.counter = start;
        }
        public Object getValue()
        {
            return counter++;
        }
    }

    public class IteratingFieldProvider implements IFieldProvider
    {
        Integer counter;
        SObjectField fToExtract;
        List<SObject> listToIter;
        public IteratingFieldProvider(List<SObject> listToIterate, SObjectField fieldToExtract)
        {
            this.counter=0;
            this.listToIter = listToIterate;
            this.fToExtract = fieldToExtract;
        }

        public IteratingFieldProvider(List<SObject> listToIterate)
        {
            this.counter=0;
            this.listToIter = listToIterate;
        }

        public Object getValue()
        {
            Sobject itemX = listToIter.get(counter++);
            if(fToExtract!=null)
                return itemX.get(fToExtract);

            if(itemX.get('Id')!=null)
                return itemX.get('Id');

            return itemX;
        }
    }

    public class UniqueDateProvider implements IFieldProvider
    {
        final Date startDate;
        Integer counter;
        public UniqueDateProvider() { this(Date.today()); }
        public UniqueDateProvider(Date startDate)
        {
            this.counter = 0;
            this.startDate = startDate;
        }
        public Object getValue()
        {
            return startDate.addDays(counter++);
        }
    }

	public class UniqueStringProvider implements IFieldProvider
    {
        final String base;
        Integer counter;
        public UniqueStringProvider() { this(''); }
        public UniqueStringProvider(String base)
        {
            this.base = base;
            this.counter = 0;
        }
        public Object getValue()
        {
            this.counter++;
            return base.replaceAll('_PLACEHOLDER', String.valueOf(counter));
        }
    }

    public virtual class UniqueFixedLengthStringProvider implements IFieldProvider
    {
        final String base;
        final Integer remainingLength;
        Integer counter;
        
        public UniqueFixedLengthStringProvider(Integer length) { this('', length); }
        public UniqueFixedLengthStringProvider(String base, Integer length)
        {
            this.base = base;
            this.remainingLength = length - base.length();
            this.counter = 0;
        }
        public Object getValue()
        {
            String counterValue = String.valueOf(counter++);
            Integer counterLength = counterValue.length();
            if (counterLength < remainingLength)
                counterValue = counterValue.leftPad(remainingLength).replace(' ', '0');
            else if (counterLength > remainingLength)
                throw new CountException('Too many fixed length strings');
            return base + counterValue;
        }
    }
    public class DummyIdProvider
        extends UniqueFixedLengthStringProvider implements IFieldProvider
    {
        public DummyIdProvider(String prefix, Integer length) { super(prefix, length); }
        public DummyIdProvider(SObjectType sObjectType) { this(sObjectType, 18); }
        public DummyIdProvider(SObjectType sObjectType, Integer length)
        {
            this(sObjectType.getDescribe().getKeyPrefix(), length);
        }
    }
    
    public virtual class ListProvider implements IFieldProvider
    {
        final Integer size;
        final List<Object> values;
        Integer index;
        public ListProvider(List<Object> values)
        {
            this.values = values;
            this.size = values.size();
            this.index = 0;
        }
        public Object getValue()
        {
            Object value = values[index];
            index = Math.mod(index + 1, size);
            return value;
        }
    }
    public class MultiParentProvider extends ListProvider implements IFieldProvider
    {
        public MultiParentProvider(Set<Id> parentIds)
        {
            super(new List<Id>(parentIds));
        }
        public MultiParentProvider(List<SObject> parents)
        {
            this(pluckIds(parents));
        }
    }
    
    public class StringListProvider extends ListProvider implements IFieldProvider
    {
        public StringListProvider(List<String> myStrings)
        {
            super(myStrings);
        }
    }

    public class GenericParentProvider implements IFieldProvider
    {
        final SObjectBuilder builder;
        Id genericParentId;
        public GenericParentProvider(SObjectType sObjectType)
        {
            this.builder = new SObjectBuilder(sObjectType);
        }
        public GenericParentProvider(SObjectType sObjectType, SObjectField field, Object value)
        {
            this.builder = new SObjectBuilder(sObjectType).put(field, value);
        }
        public Object getValue()
        {
            if (genericParentId == null)
                genericParentId = builder.eagerPopulate().create().getRecord().Id;
            return genericParentId;
        }
    }
    
    public class QueryParentProvider implements IFieldProvider
    {
        final String query;
        Id queriedParentId;
        public QueryParentProvider(String query)
        {
            this.query = query;
        }
        public QueryParentProvider(SObjectType sObjectType)
        {
            this.query = 'SELECT Id FROM ' + String.valueOf(sObjectType) + ' LIMIT 1';
        }
        public Object getValue()
        {
            if (queriedParentId == null)
            {
                List<SObject> candidates = Database.query(query);
                if (candidates.isEmpty()) throw new EmptyQueryException();
                queriedParentId = candidates[0].Id;
            }
            return queriedParentId;
        }
    }

    public class IndustryVerticalMappingProvider implements IFieldProvider
    {
        Integer counter;
        List<Industry_Vertical_Sub_Vertical_Mapping__c> verticals;

        public IndustryVerticalMappingProvider()
        {
            this.counter=0;
            verticals = new List<Industry_Vertical_Sub_Vertical_Mapping__c>();
            verticals.add(new Industry_Vertical_Sub_Vertical_Mapping__c(Name='TTST1',Industry__c='Commerce', Vertical__c='Public Sector', Sub_Vertical__c='PS - Higher Ed'));
            verticals.add(new Industry_Vertical_Sub_Vertical_Mapping__c(Name='TTST2',Industry__c='Enterprise', Vertical__c='Energy & Utilities', Sub_Vertical__c='Oil & Gas'));
            verticals.add(new Industry_Vertical_Sub_Vertical_Mapping__c(Name='TTST3',Industry__c='Enterprise', Vertical__c='Energy & Utilities', Sub_Vertical__c='Utilities'));
        }

        public Object getValue()
        {
            return verticals.get(counter++);
        }
    }

    public class Product2Provider implements IFieldProvider
    {
        Integer counter;
        List<Product2> prods; 

        public Product2Provider()
        {
            this.counter=0;
            this.prods = new List<Product2>();
            prods.add(new Product2(Name='OtherProduct1', Family='Other',IsActive=true,CurrencyIsoCode='INR', AKAM_Product_Id__c='F-PR-275'));
            prods.add(new Product2(Name='WebProduct1', Family='Web',IsActive=true,CurrencyIsoCode='INR',AKAM_Product_Id__c='F-PR-276'));
            prods.add(new Product2(Name='CarrierProduct1', Family='Carrier',IsActive=true,CurrencyIsoCode='INR',AKAM_Product_Id__c='F-PR-277'));


        }

        public Object getValue()
        {
            return prods.get(counter++);
        }
    }

    public class TerritoryMappingProvider implements IFieldProvider
    {
        Integer counter;
        List<Territory_Mapping__c> tms;

        public TerritoryMappingProvider()
        {
            List<String> territoryMappingRecords = GSMUtilClass.getGsmSettingValue('Territory_Mapping_Records').split(';');
            this.counter=0;
            tms= new List<Territory_Mapping__c>();

            /*
            tms.add(utilTestClass.createTerritoryMapping('Carrier APJ - Carrier ANZ', 'APJ', 'Carrier APJ'));
            tms.add(utilTestClass.createTerritoryMapping('Greater China - Hong Kong Enterprise', 'APJ', 'Hong Kong'));
            tms.add(utilTestClass.createTerritoryMapping('Korea - Korea Farmer', 'APJ', 'Korea Enterprise'));
            tms.add(utilTestClass.createTerritoryMapping('APJ Channels - Japan Channels', 'APJ', 'Japan Channels'));
            tms.add(utilTestClass.createTerritoryMapping('APJ Channels - India Channels', 'APJ', 'India Channels'));
            tms.add(utilTestClass.createTerritoryMapping('Central & South - Mexico1', 'LATAM', 'Mexico'));
            tms.add(utilTestClass.createTerritoryMapping('CER - CER Media', 'EMEA', 'CER Media'));*/

            tms.add(utilTestClass.createTerritoryMapping(territoryMappingRecords[0].split(',')[0],territoryMappingRecords[0].split(',')[1],territoryMappingRecords[0].split(',')[2]));
            tms.add(utilTestClass.createTerritoryMapping(territoryMappingRecords[1].split(',')[0],territoryMappingRecords[1].split(',')[1],territoryMappingRecords[1].split(',')[2]));
            tms.add(utilTestClass.createTerritoryMapping(territoryMappingRecords[2].split(',')[0],territoryMappingRecords[2].split(',')[1],territoryMappingRecords[2].split(',')[2]));
            tms.add(utilTestClass.createTerritoryMapping(territoryMappingRecords[3].split(',')[0],territoryMappingRecords[3].split(',')[1],territoryMappingRecords[3].split(',')[2]));
            tms.add(utilTestClass.createTerritoryMapping(territoryMappingRecords[4].split(',')[0],territoryMappingRecords[4].split(',')[1],territoryMappingRecords[4].split(',')[2]));
            tms.add(utilTestClass.createTerritoryMapping(territoryMappingRecords[5].split(',')[0],territoryMappingRecords[5].split(',')[1],territoryMappingRecords[5].split(',')[2]));
        }

        public Object getValue()
        {
            return tms.get(counter++);
        }
    }

    static Set<Id> pluckIds(List<SObject> records)
    {
        Map<Id, SObject> recordMap = new Map<Id, SObject>();
        recordMap.putAll(records);
        return recordMap.keySet();
    }

    static Map<String, IFieldProvider> cache = new Map<String, IFieldProvider>();

    public static IFieldProvider getUniqueStringProvider()
    {
        return getProvider('Unique String');
    }
    public static IFieldProvider getUniqueEmailProvider()
    {
        return getProvider('Unique Email');
    }

    public static IFieldProvider getProduct2Provider()
    {
        return getProvider('Product2');
    }

    public static IFieldProvider getProvider(String providerType)
    {
        if(cache.containsKey(providerType))
            return cache.get(providerType);

        IFieldProvider provider ;
        if(providerType == 'Industry_Vertical_Sub_Vertical_Mapping__c')
        {
            provider = new SobjectFieldProviders.IndustryVerticalMappingProvider();
        }
        if(providerType == 'Product2')
        {
            provider = new SobjectFieldProviders.Product2Provider();
        }
        else if(providerType == 'Territory_Mapping__c')
        {
            provider = new SobjectFieldProviders.TerritoryMappingProvider();
        }
        else if(providerType == 'Unique String')
        {
            provider = new SobjectFieldProviders.UniqueStringProvider(TEST_USER_PREFIX+'_PLACEHOLDER');
        }
        else if(providerType == 'Fixed Length String')
        {
            provider = new SobjectFieldProviders.UniqueFixedLengthStringProvider('TSTSRMAC', 10);
        }
        else if(providerType == 'Unique Website')
        {
            provider = new SobjectFieldProviders.UniqueStringProvider(TEST_website_PREFIX+'_PLACEHOLDER.com');
        }
        else if(providerType == 'Unique Email')
        {
            provider = new SobjectFieldProviders.UniqueStringProvider(TEST_USER_PREFIX+'_PLACEHOLDER@akamai.com');
        }
        cache.put(providerType, provider);


        return provider;
    }
}