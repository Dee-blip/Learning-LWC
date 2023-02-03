/***
    PSA_ProjectContractSelectController
    @author Suhas Jain
    @Description : This Class is used as controller for the Project Contract Select LWC Component , which will be used
                    in both the project creation and detail page.
                   
	@History
	--Developer		      --Date			--Change
	Suhas Jain    	  29/01/2021		Created the class.	   
*/
public class PSA_ProjectContractSelectController{

    public static List<PSA_SelectableObject> contractWithDetailswrap = new List<PSA_SelectableObject>();
    public static Id accountId ;

    @AuraEnabled
    public static string saveProject(String detailIdstr, String contractIdstr, String projIdstr)
    {
        List<Project_Contract_Line_Item__c> pcliList = new List<Project_Contract_Line_Item__c>();
        Project_Contract_Line_Item__c pcli = new Project_Contract_Line_Item__c();
        Project_Contract__c projContHeader = new Project_Contract__c();
        Merge_Contract_Detail__c mergeDetail = new 	Merge_Contract_Detail__c();
        Id contractId = Id.valueOf(contractIdstr);
        Id detailId = Id.valueOf(detailIdstr);
        Id projId = Id.valueOf(projIdstr);

        System.debug('got id ' + detailIdstr + ' con id : ' + contractIdstr + ' proj id : ' + projIdstr);
        List<Project_Contract__c> prevProjContract = new List<Project_Contract__c>();

        // Query Merge contracts and project contract to be used while preparing 
        prevProjContract = [select id,Account__c , Original_Contract_Id__c , Project__c from Project_Contract__c where Project__c = :projIdstr   ];

        mergeDetail = [select id , Original_Contract_Id__c , Original_Contract_Id__r.Account_Name__c from Merge_Contract_Detail__c where id = :detailIdstr ];
        //projContHeader = prevProjContract;
        projContHeader.Account__c = mergeDetail.Original_Contract_Id__r.Account_Name__c ;
        projContHeader.Original_Contract_Id__c = mergeDetail.Original_Contract_Id__c ;
        projContHeader.Project__c = Id.valueOf(projIdstr) ;
        System.debug(' projContHeader ' + projContHeader);
        try {

            Database.SaveResult result1;

            // check if a project contract already exists and insert only if not present , and if the prev project contract already 
            // had the same contract as the present selected contract detail's contract
            if( (prevProjContract.isEmpty() || prevProjContract == null ) || ( prevProjContract != null && !prevProjContract.isEmpty() && prevProjContract[0].Original_Contract_Id__c != contractId )   )
            {
                result1 =  Database.insert(projContHeader,false);            
            }
            else { projContHeader.Id = prevProjContract[0].Id ;  }
    
            System.debug('result1 ' + result1);
            // PCLI will always be inserted since if the selected cli and the previous present PCLI values are same , validation is done
            // in the LWC part to not make a salesforce call
            pcli.Contract_Detail__c = mergeDetail.Id ;
            pcli.Original_Contract_Id__c = mergeDetail.Original_Contract_Id__c ;
            pcli.Project__c = Id.valueOf(projIdstr) ;
            pcli.Valid_Create__c = true;
            pcli.Project_Contract__c = projContHeader.Id;
            pcliList.add(pcli);

            System.debug('going in ' + pcli );
            list<Database.SaveResult> results = Database.insert(pcliList,false);
            System.debug('result ' + results);
        }  catch (Exception e) {
            String error = CommonUtilClass.ExtractValidationExMsg( e ) ;
            System.debug('error :' + e);
        }
        
        return detailIdstr;
    }

    @AuraEnabled(cacheable=true)
    public static List<PSA_SelectableObject> getContractWithDetails(String projectId , Integer offset , String productFilter , String dateFilter  ){

        // IMPORTANT NOTE - When loading contract headers, assumption is out of first 30 contracts quired atleast 10 are valid  , else if less than 10 are valid then 
        //next contracts apart from these 30 are not loaded since the scollbar will not be present and systems fectches next 30 only when scrollbar reaches to the bottom

        List<Merge_Contract_Header__c> contractList = new List<Merge_Contract_Header__c>();
        List<PSA_SelectableObject> contractWithDetailswrapNew = new List<PSA_SelectableObject>();
        Id accountId ;
        Set<String> productSet=new Set<String>() ;
        list<PSA_Products__c> PSAProductNames= new list<PSA_Products__c>();
        String selectedId = getSelectedCli(projectId);
        PSAProductNames=[select Id,Name,Product_Name__c from PSA_Products__c];
        String whereClause = '';
        for(PSA_Products__c psa_productNameIterator:PSAProductNames)
        {
            // check if the method has product filter set , if so , see if the product filter has product presnt in PSA products custom setting
            // and add only that product to the product set , else add all the PSA Products to product set to fitler the contract details
            if(productFilter != '' && productFilter != 'class-none' && psa_productNameIterator.Product_Name__c.contains(productFilter)  )
            {
                productSet.add(psa_productNameIterator.Product_Name__c);
            } else if(productFilter == '' || productFilter == 'class-none')
            {
                productSet.add(psa_productNameIterator.Product_Name__c);
            }
            
        }

        System.debug('product name :' + projectId + ' offset ' + offset + ' productFilter : '  + productFilter + ' date filter::  ' + dateFilter );
        System.debug('r name :' + offset );

        // Check if the project id parameter has a project id or account id , and populate the account id accordingly
        if( projectId != null && projectId.startsWith('aAE') )
        {
            projectId = projectId.split(',')[0];
            accountId = [select pse__Account__c from pse__proj__c where id = : projectId ].pse__Account__c ;
            System.debug('got the account :' + accountId );
        } else if (projectId != null && projectId.startsWith('001'))
        {
            accountId = projectId;
        }

        // contruct the where clause depending on the date filter set , this variable will be used in query, the default value of the 
        // date filter passed will be "Active"
        if(dateFilter != null && dateFilter != '' )
        {
            if(dateFilter == 'Active')
            {
                whereClause = whereClause + ' Effective_End_Date__c >= TODAY ' ;
            }
            else if( dateFilter == 'Expired' )
            {
                whereClause = whereClause + ' Effective_End_Date__c = LAST_N_DAYS:90 AND Effective_End_Date__c < TODAY ' ;
            }
            else { 
                whereClause = whereClause + ' Effective_End_Date__c < LAST_N_DAYS:90 AND Effective_End_Date__c = LAST_N_DAYS:455 AND Effective_End_Date__c < TODAY ';
             }
        }

        System.debug(' wher clau :' + whereClause);


        if ( projectId != null && projectId != '' ) {

            String Query = 'select id, Name,Revision_Contract_Id__c,Parent_Contract__c, Parent_Contract__r.Name ,Active__c, Effective_End_Date__c,Effective_Start_Date__c, Revision_Effective_Start_Date__c, Opportunity_Name__c , Opportunity_Name__r.Name , Account_Name__c , Account_Name__r.Name , (SELECT Id, Product__c ,Name, Original_Contract_Id__c, Effective_Start_Date__c, Effective_End_Date__c , Unit_Price__c , Units_Low__c , Units_High__c , Record_Type__c , Unit_of_Measure__c  FROM Merge_Contract_Details__r WHERE ID != NULL AND '+ whereClause +  '  ORDER BY Name limit 990 ) from Merge_Contract_Header__c WHERE Account_Name__c = :accountId  order by createddate asc limit 30 OFFSET :offset';

            System.debug(' Query :' + 'select id, Name , (SELECT Id, Product__c ,Name  FROM Merge_Contract_Details__r WHERE ID != NULL ORDER BY Name limit 1500) from Merge_Contract_Header__c WHERE Account_Name__c = :accountId AND ' + whereClause +  '  order by createddate asc limit 30 OFFSET : ' + offset  );

            contractList = Database.query(Query);
            
        }


        

        for ( Merge_Contract_Header__c  header : contractList) {
            PSA_SelectableObject headerWrap = new PSA_SelectableObject();
            headerWrap.obj = header ;
            headerWrap.hyperLink = '/' + header.Id; // Hyperlink to be used in the html anchor tag for the records
            headerWrap.accountLink = '/' + header.Account_Name__c ;
            headerWrap.parentContractLink = '/' + header.Parent_Contract__c ;
            headerWrap.expanded = false;
            
            List<PSA_SelectableObject> detailListWrap = new List<PSA_SelectableObject>();
            Integer detailCount = 0;


            
            for (Merge_Contract_Detail__c detail : header.Merge_Contract_Details__r ) {
                // since 1500 contract details are fetched , break the loop once the first 15 valid contract details are found.
                if( !detailListWrap.isEmpty() && detailListWrap != null && detailListWrap.size() == 15 )
                {
                    headerWrap.offset = detailCount;
                    break;
                }
                detailCount ++ ;


                
                if(productSet.contains(detail.Product__c))
                {
                    PSA_SelectableObject detailWrap = new PSA_SelectableObject();
                    detailWrap.obj = detail ;
                    detailWrap.hyperLink = '/' + detail.Id;
                    System.debug(' selcetd condtn : ' + selectedId + ' del id : ' +detail.Id + ' condtn : ' + (selectedId != '' && detail.Id == selectedId ));
                    if(selectedId != '' && detail.Id == selectedId )
                    {
                        detailWrap.selected = true;
                    }
                    detailListWrap.add( detailWrap );
                }
            }


            
            if( productFilter != 'class-none' )
            {
                productFilter = productFilter + '#>' + 'class-none' ;
            }

            // After looping through 1500 contract details , if a min of 15 valid contract details are not found , then query the data base again 
            if( header.Merge_Contract_Details__r != null && !header.Merge_Contract_Details__r.isEmpty() && header.Merge_Contract_Details__r.size() >= 990  )
            {
                headerWrap.offset = detailCount;
                while(detailListWrap.isEmpty() ||  ( !detailListWrap.isEmpty() && detailListWrap != null && detailListWrap.size() <15 )  )
                {
                    System.debug(' off reach? ' + headerWrap.offset);
                    List<PSA_SelectableObject> nextDetailWrapList = new List<PSA_SelectableObject>();
                    nextDetailWrapList = getMoreDetails(String.valueOf(header.Id) , headerWrap.offset , productFilter , String.valueOf(selectedId) , dateFilter );

                    headerWrap.offset = headerWrap.offset + 1000;
                    if(headerWrap.offset > 3000)
                    {
                        headerWrap.offset = 50001;
                    }
                    

                    if(nextDetailWrapList == null )
                    {
                        break; // breaking if after all the contract details are fetched and still a min of 15 contract details are not found
                    } else if( nextDetailWrapList != null && !nextDetailWrapList.isEmpty() && nextDetailWrapList.size() >0 )
                    {
                        detailListWrap.addAll( nextDetailWrapList );
                    }
                    
                }
            }
            

            headerWrap.childObjects = detailListWrap;
            if( detailListWrap != null && detailListWrap.size() > 0 )
            {
                contractWithDetailswrap.add(headerWrap);
            }
            
        }
        
        return contractWithDetailswrap;
         
    }

    @AuraEnabled(cacheable=true)
    public static String getSelectedCli(String projId)
    {
        List<Project_Contract_Line_Item__c> pcliList = new List<Project_Contract_Line_Item__c>();
        pcliList = [select id, Contract_Detail__c from Project_Contract_Line_Item__c where Project__c = :projId ];

        if( (!pcliList.isEmpty()) && pcliList.size()>0 )
        {
            return pcliList[0].Contract_Detail__c ;
        }else return '';

    }

    @AuraEnabled(cacheable=true)
    public static List<PSA_SelectableObject> getMoreDetails(String productName, Integer detailOffset, String productFilter , String selectedId, String dateFilter)
    {
        list<PSA_Products__c> PSAProductNames= new list<PSA_Products__c>();
        Set<String> productSet=new Set<String>() ;
        PSAProductNames=[select Id,Name,Product_Name__c from PSA_Products__c];
        String whereClause = '';
        Integer limitval = 15;

        if(dateFilter != null && dateFilter != '' )
        {
            if(dateFilter == 'Active')
            {
                whereClause = whereClause + ' Effective_End_Date__c >= TODAY ' ;
            }
            else if( dateFilter == 'Expired' )
            {
                whereClause = whereClause + ' Effective_End_Date__c = LAST_N_DAYS:90 AND Effective_End_Date__c < TODAY ' ;
            }
            else { 
                whereClause = whereClause + ' Effective_End_Date__c < LAST_N_DAYS:90 AND Effective_End_Date__c = LAST_N_DAYS:455 AND Effective_End_Date__c < TODAY ';
             }
        }

        if( detailOffset == 50001)
        { return null; }

        if(productFilter == 'class-none' || productFilter.contains('class-none')  )
        {
            limitval = 1000;
        }

        if(detailOffset > 2000)
        {
            detailOffset = 2000 ;
            limitval = 50000;
        }

        if(productFilter.contains('class-none'))
        {
            productFilter = productFilter.split('#>')[0];
        }

        for(PSA_Products__c psa_productNameIterator:PSAProductNames)
        {
            if(productFilter != '' && productFilter != 'class-none' && psa_productNameIterator.Product_Name__c.contains(productFilter)  )
            {
                productSet.add(psa_productNameIterator.Product_Name__c);
            } else if(productFilter == ''  || productFilter == 'class-none')
            {
                productSet.add(psa_productNameIterator.Product_Name__c);
            }
        }

        


        System.debug(' prod name : ' + productName + '  detaul odd set ' + detailOffset );

        System.debug(' productName:: ' + productName + ' detailOffset:: ' + detailOffset + ' productFilter:: ' + productFilter + ' selectedId:: ' + selectedId + ' dateFilter:: ' + dateFilter);

        List<PSA_SelectableObject> detailList = new List<PSA_SelectableObject>();

        List<Merge_contract_detail__c> mergeDetailList = new List<Merge_contract_detail__c>();

        String Query = ' select Id, Product__c ,Name, Effective_Start_Date__c, Effective_End_Date__c , Unit_Price__c , Units_Low__c , Units_High__c , Record_Type__c ,Original_Contract_Id__c, Unit_of_Measure__c FROM Merge_contract_detail__c where Original_Contract_Id__c = :productName AND ' + whereClause  + ' ORDER BY Name  limit :limitval  OFFSET :detailOffset ';

        mergeDetailList = Database.query(Query);

        //mergeDetailList = [select Id, Product__c ,Name, Effective_Start_Date__c, Effective_End_Date__c , Unit_Price__c , Units_Low__c , Units_High__c , Record_Type__c ,Original_Contract_Id__c, Unit_of_Measure__c FROM Merge_contract_detail__c where Original_Contract_Id__c = :productName AND :whereClause ORDER BY Name  limit :limitval  OFFSET :detailOffset ];

        if( mergeDetailList != null && mergeDetailList.size() == 0 )
        {
            return null;
        }

        for( Merge_contract_detail__c detail : mergeDetailList )
        {
            system.debug(' detail : ' + detail.Name + ' detail.Product__c:: ' + detail.Product__c + ' containsprod:: ' + (productSet.contains(detail.Product__c)) );
            if(productSet.contains(detail.Product__c))
            {
                PSA_SelectableObject detailWrap = new PSA_SelectableObject();
                detailWrap.obj = detail ;
                detailWrap.hyperLink = '/' + detail.Id;
                if( selectedId != '' && detail.Id == selectedId )
                {
                    detailWrap.selected = true;
                }
                detailList.add( detailWrap );
            }
        }

        return detailList;

    }
}