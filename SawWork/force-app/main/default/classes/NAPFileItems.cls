public class NAPFileItems
{
    public static String exceptionMessage {get;set;}

    public static List<ContentVersion> getFiles(NAP_File_Filter__c filter,Boolean isFileBrowser)
    {
        List<ContentVersion> contentVersionList = new List<ContentVersion>();

        al.SoqlBuilder queryBuilder = new al.SoqlBuilder()
            .selectx(new List<String>{'Id', 'ContentDocumentId', 'ContentSize', 'ContentUrl', 'FileExtension', 'FileType', 'IsDeleted', 'IsLatest','Tag__c','TagCsv','Title', 'Display_Title__c', 'LastModifiedDate','Language__c'}).fromx('ContentVersion').orderByx(new al.OrderBy('Title'));

        al.NestableCondition filterCondition = getFilterCondition();


        if(filter.File_Resource_IDs__c==null)
        {
            al.NestableCondition tagCondition = getTagCondition(filter);
            system.debug('HC tag condition '+tagCondition);

            if(filter.Attribute_Filters__c!=null)
            {

                List<String> filesFilteredBasedOnAttributes = getFilesFilteredBasedOnAttributes(filter);

                if(filter.Tag_to_Attribute_Condition__c!=null)
                {

                    // tags and attributes
                    al.NestableCondition tagPlusAttributes =initializeCondition(filter.Tag_to_Attribute_Condition__c).add(tagCondition);

                    if(filesFilteredBasedOnAttributes.size()>0)
                    {
                        tagPlusAttributes = tagPlusAttributes.add(new al.SetCondition('Id').inx(filesFilteredBasedOnAttributes));
                    }
                    else
                    {
                        // attribute condition returns zero match
                        if(filter.Tag_to_Attribute_Condition__c.containsIgnoreCase('AND'))
                        {
                            return contentVersionList;
                        }
                    }
                    filterCondition.add(tagPlusAttributes);

                }
                else
                {
                    //only attributes
                    if(filesFilteredBasedOnAttributes.size()>0)
                    {
                        filterCondition.add(new al.SetCondition('Id').inx(filesFilteredBasedOnAttributes));
                                        system.debug('HC Attribute filterCondition '+filterCondition);

                    }
                    else
                    {
                        return contentVersionList;
                    }
                }
            }
            else
            {
                // only tags
                filterCondition.add(tagCondition);
                system.debug('HC tag filterCondition '+filterCondition);

            }
        }
        else
        {
            //only file resource ids
            filterCondition.add(getFileIdsCondition(filter));
        }

        // filter out files which have attributes other than the current user's attributes

        String query = queryBuilder.wherex(filterCondition).toSoql(new al.SoqlOptions().wildcardStringsInLikeOperators());
        system.debug('HC query '+query +'Is File Browser '+isFileBrowser);


        try
        {
            contentVersionList = Database.query(query);
            // SFDC-941 & SFDC-842 : If file browser, make sure you get only public files i.e. files without any attributes
            if(isFileBrowser)
            {
                contentVersionList = getFilesWithoutAttributes(contentVersionList);
            }
        }
        catch(Exception exc)
        {
            exceptionMessage = 'The generated file query for the file filter : '+ filter.Id + ' was : <br/><br/>' + query + '<br/><br/><br/> And the exception was <br/><br/>' + exc.getMessage();
            System.Debug('AGH_ERROR' + exceptionMessage);
        }


        return contentVersionList;
    }


    private static al.NestableCondition initializeCondition(String cond)
    {
        if(!String.isBlank(cond) && cond.equals('AND'))
        {
            return new al.AndCondition();
        }
        else
        {
            return new al.OrCondition();
        }
    }

    private static al.NestableCondition getTagCondition(NAP_File_Filter__c filter)
    {
        al.NestableCondition tagCondition = initializeCondition(filter.Tag_Condition__c);
        if(filter.Tag_Filter_Long__c!=null)
        {
            for(String tag : filter.Tag_Filter_Long__c.split(','))
            {
                tagCondition = tagCondition.add(new al.FieldCondition('Tag__c').likex(tag.trim()));
            }
        }
        return tagCondition;
    }

    private static al.NestableCondition getFileIdsCondition(NAP_File_Filter__c filter)
    {
        // This will trim each string and the main string also
        List<String> fileResourceIds = filter.File_Resource_IDs__c.split('\\s*,\\s*');

        al.NestableCondition fileIdsCondition = new al.OrCondition().add(new al.SetCondition('ContentDocumentId').inx(fileResourceIds)).add(new al.SetCondition('Id').inx(fileResourceIds));

        return fileIdsCondition;
    }

    private static al.NestableCondition getAttributeCondition(NAP_File_Filter__c filter)
    {
        al.NestableCondition attributeSeparationCondition = new al.OrCondition();


        for(String attribute : filter.Attribute_Filters__c.split(';'))
        {
            if(attribute=='Partner Account')
            {
                attributeSeparationCondition = attributeSeparationCondition.add(new al.FieldCondition().field('Partner_Account__c').equals(CurrentUser.attributes.get(attribute)));
            }
            else
            {

                attributeSeparationCondition = attributeSeparationCondition.add(new al.AndCondition().add(new al.FieldCondition().field('Attribute_Name__c').equals(attribute)).add(new al.FieldCondition().field('Attribute_Value__c').equals(CurrentUser.attributes.get(attribute))));

            }
        }
        return attributeSeparationCondition;
    }


    /*
    private static List<String> getFilesOutsideCurrentUserSecurityContext()
    {
        // I'm assuming that a file wont have multiple attributes of the same name

        List<String> filesOutsideCurrentUserSecurityContext= new List<String>();

        System.Debug('AGH_ ' + CurrentUser.attributes.get('Partner Account') + 'an ' + CurrentUser.attributes.get('Tier'));

        // TODO - skip for internal
        // do distinct ContentVersionId__c
        
        for(ContentVersionAttribute__c cva : [select ContentVersionId__c from ContentVersionAttribute__c where (Attribute_Name__c='Partner Account' and Partner_Account__c!= :CurrentUser.attributes.get('Partner Account') and Partner_Account__c!=null) or (Attribute_Name__c='Tier' and Attribute_Value__c!= :CurrentUser.attributes.get('Tier'))])
        {
            filesOutsideCurrentUserSecurityContext.add(cva.ContentVersionId__c);
        }
        return filesOutsideCurrentUserSecurityContext;
    }
    */



    private static List<String> getFilesFilteredBasedOnAttributes(NAP_File_Filter__c filter)
    {
        al.SoqlBuilder attributeQueryBuilder = new al.SoqlBuilder().selectx('ContentVersionId__c').fromx('ContentVersionAttribute__c').wherex(getAttributeCondition(filter));


        List<String> filesFilteredBasedOnAttributes = new List<String>();

        System.Debug('files outside'+attributeQueryBuilder.toSoql());

        Map<String, Integer> contentVersionIdToNumberOfAttributes = new Map<String, Integer>();

        for(ContentVersionAttribute__c cva : Database.query(attributeQueryBuilder.toSoql())){
            Integer currentCount = contentVersionIdToNumberOfAttributes.get(cva.ContentVersionId__c)==null ? 0: contentVersionIdToNumberOfAttributes.get(cva.ContentVersionId__c);

            contentVersionIdToNumberOfAttributes.put(cva.ContentVersionId__c, currentCount+1);

            filesFilteredBasedOnAttributes.add(cva.ContentVersionId__c);
        }
        //if attribute separation condition is OR, return all. If its AND then return only those which satisfy all
        if('AND'.equals(filter.Attribute_Condition__c))
        {
            System.Debug('filtering AND');
            List<String> filesSatisfyingAll = new List<String>();

            Integer numberOfAttributes = filter.Attribute_Filters__c.split(';').size();

            for(integer i=filesFilteredBasedOnAttributes.size()-1;i>=0;i--){
                if(contentVersionIdToNumberOfAttributes.get(filesFilteredBasedOnAttributes[i])!=numberOfAttributes){
                    filesFilteredBasedOnAttributes.remove(i);
                }
            }

        }
        System.Debug('AGH_ size'+filesFilteredBasedOnAttributes.size());
        return filesFilteredBasedOnAttributes;
    }


    private static al.NestableCondition getFilterCondition()
    {
        al.NestableCondition filterCondition = new al.AndCondition().add(new al.FieldCondition('isLatest',true));
            
        /*
        List<String> filesOutsideCurrentUserSecurityContext = getFilesOutsideCurrentUserSecurityContext();
        if(filesOutsideCurrentUserSecurityContext.size()>0)
        {
            filterCondition = filterCondition.add(new al.SetCondition('Id', al.Operator.NOT_IN, filesOutsideCurrentUserSecurityContext));
        }
        */
        return filterCondition;
    }

     // SFDC-941 & SFDC-842 : If file browser, make sure you get only public files i.e. files without any attributes
    private static List<ContentVersion> getFilesWithoutAttributes(List<ContentVersion> contentVersionList)
    {
        List<ContentVersionAttribute__c> setOfFileIdsWithAttributes = new List<ContentVersionAttribute__c>();
        Map<String,ContentVersion> mapOfIdToContentVersion = new Map<String,ContentVersion>();

        for(ContentVersion cvItem : contentVersionList)
            mapOfIdToContentVersion.put(String.valueOf(cvItem.Id), cvItem);

        System.debug('before:: mapOfIdToContentVersion ' + mapOfIdToContentVersion);

        // get list of files that contain attributes defined in ContentVersionAttribute__c object
        setOfFileIdsWithAttributes = [Select Name,ContentVersionId__c,Attribute_Name__c,Attribute_Value__c  from ContentVersionAttribute__c where ContentVersionId__c IN :mapOfIdToContentVersion.keySet()];

        System.debug('setOfFileIdsWithAttributes'+ setOfFileIdsWithAttributes);
        // exclude all files that contain attributes 
        for(ContentVersionAttribute__c file :setOfFileIdsWithAttributes)
        {
            if(mapOfIdToContentVersion.containsKey(file.ContentVersionId__c))
                mapOfIdToContentVersion.remove(file.ContentVersionId__c);
        }

        System.debug('after : mapOfIdToContentVersion' + mapOfIdToContentVersion);
        return mapOfIdToContentVersion.values();

    } 
}