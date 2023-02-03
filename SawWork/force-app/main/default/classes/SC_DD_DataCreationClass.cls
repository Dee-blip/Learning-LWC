/*=====================================================================================================+
Class name          :   SC_DD_DataCreationClass
Author              :   Vamsee
Created             :   10-Dec-19
Purpose             :   Class to create Deal Desk service Products and related objects. 

Test Class          :   SC_DD_DealDeskTest

Last Modified   Developer                 Purpose             
=============   ========================  =======
10-Mar-2020     Himanshu,Vishnu, Vamsee    Initial Development(Jira Ticket# FFPSA-850) 
18-May-2020     Vamsee                     Added MSS Product (ESESP-3376)
20-May-2020     Vishnu Vardhan             Update Package Components of Advanced Prod(ESESP-3578)
21-Dec-2020     Vishnu Vardhan             ESESP-4301 Refactored Portfolio (SOA, RRS, MSS) 2.0
+=====================================================================================================*/
public class SC_DD_DataCreationClass {
    
    //List to insert Package Components 
    List<SC_DD_Package_Components__c> pckCompList = new List<SC_DD_Package_Components__c>();
    
    //List to insert Product Pricing records
    List<SC_DD_Product_Pricing__c> prdPricingList = new List<SC_DD_Product_Pricing__c>();
    Id prodPricingRecTypeId = Schema.SObjectType.SC_DD_Product_Pricing__c.getRecordTypeInfosByName().get('Product').getRecordTypeId();

    //Constructor
    public SC_DD_DataCreationClass(String dataType){
        if(dataType == 'Marketing Product'){
            createMarketingProducts();
        }
        
        else if(dataType == 'Marketing Product (Others)'){
            createOtherMarketingProducts();
        }
        else if(dataType == 'GSS Products'){
            //Product #1.1 - SOA -> Kona Site Defender
            createSOA_KSD();
            //Product #1.2 - SOA -> Web Appln Firewall
            createSOA_WAF();
            //Product #1.3 - SOA -> Bot Manager
            createSOA_Bot();
            //Product #1.4 - SOA -> Prolexic
            createSOA_Prolexic();
            //Product #1.5 - SOA -> EAA/ETP
            createSOA_EAA();
            //Product #2 - SMP
            createSMP();
            //Product #3 - Premium 2.0
            createPremium2();
            //Product #4 - RRS   
            createRRS();
            //Product #5 - PnP: Managed Kona & SMP
            createPnPKonanSMP();
            //Product #6 - PnP: SOA & SMP
            createPnPSOAnSMP();
            //Product #7 - PnP: Premium 2.0 & Managed Kona  
            createPnPPremiumnKona();
            //Product #8 - PnP: Premium 2.0 & SOA
            createPnPPremiumnSOA();
            //Product #9 - Managed Kona
            createManagedKona();
            //Product #10.1 - Standard Integration->Security Product
            createSIServiceProduct();
            //Product #10.2 - Standard Integration->Non-Security Product
            createSInonServiceProduct();
            //Product #11.1 - Managed Integration->Security Product
            createMIServiceProduct();
            //Product #11.2 - Managed Integration->Non-Security Product
            createMInonServiceProduct();
            //Product #12 - Advanced
            createAdvanced();
            //Product #13.1 - Plus->Standard Entitlements
            createPlusSE();
            //Product #13.2 - Plus->Scaled-down version for DSA + WAP
            createPlusDSA();
            //Product #14 - TAS
            createTAS();
            //Product #15 - PS - Enterprise
            createPSEnterprise();
            //Product #16 - PS - Security
            createPSSecurity();
            //Product #17 - Premium 3.0
            createPremium3();
            //Product #18.1 - MSS ->KSD
            createMSSKSD();
            //Product #18.2 - MSS ->BMP
            createMSSBMP();
            //Product #18.3 - MSS ->KSD + BMP
            createMSSKSDnBMP();
        
            //Insert all the Package products for above products
            Insert pckCompList;
            
            //Insert all the pricing details for above products
            insert prdPricingList;
            
            //Other Products for Contract Mapping
            createOtherProducts();
        }
        else if(dataType == 'Mapping'){
            //Contract - call metod to insert mapping records of products without product type
            createContractMapping1();
            
            //Contract - call method to insert mapping records of products with product type
            createContractMapping2();
            
            //PS - Call Function to insert mapping records of products without product type
            createPSMapping1();
            
            //PS - Call Function to insert mapping records of products with product type
            createPSMapping2();
            
            //Akatec - call Function to insert mapping records of Support Types
            createAkaTecMapping();
            
            //SOCC - Function to insert mapping records of Case Products
            createSOCCMapping();
            
            //Customer MRR - Function to insert mapping records of products without product type
            createCustomerMRRMapping1();
            
            //Customer MRR - Function to insert mapping records of products with product type
            createCustomerMRRMapping2();
            
            //Customer MRR - Function to insert mapping records of products with multiple Customer MRR
            createCustomerMRRMapping3();
            
            //Revenue - Function to insert mapping records of products without product type
            createRevenueMapping1();
            
            //Revenue - Function to insert mapping records of products with product type
            createRevenueMapping2();
        }
        else if(dataType == 'Custom Setting'){
            createCustomSettings();
        }
        else if(dataType == 'Delete GSS Products'){
            deleteGSSProducts();
        }
        else if(dataType == 'Delete Marketing Products'){
            deleteMarketingProducts();
        }
        else if(dataType == 'Delete Mapping'){
            deleteMapping();
        }
        else if(dataType == 'MSS'){
            createMSSKSD();
            createMSSBMP();
            createMSSKSDnBMP();
            Insert pckCompList;
            Insert prdPricingList;
            MSSProduct();
            createCustomerMRRMapping3();
        }
    }
    
    //GSS Marketing Products
    public void createMarketingProducts(){
        List<string> productIdList = new List<string>{'M-LC-139829', 'M-LC-62167', 'M-LC-132413', 'M-LC-161467', 'M-LC-161469', 'M-LC-132825', 
            'M-LC-133031', 'M-LC-133237', 'B-3-5SCZIN','M-LC-120877', 'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 
            'M-LC-165944', 'M-LC-160428', 'M-LC-165776', 'M-LC-165777', 'M-LC-802', 'M-LC-134679', 'M-LC-94509', 'M-LC-801', 'M-LC-134473', 'M-LC-162752', 
            'M-LC-162622', 'M-LC-162746', 'M-LC-162633', 'M-LC-38065', 'M-LC-135915', 'M-LC-135709', '1-28210R', 'M-LC-803', 'M-LC-985', '1-11B8A', 
            'M-LC-136945', 'M-LC-37653', 'M-LC-159904', 'M-LC-134267', 'M-LC-1184', 'M-LC-1183', 'M-LC-63609', 'M-LC-134267', 'M-LC-1051', 'M-LC-165819', 'M-LC-165827',
            'M-LC-166458', 'M-LC-166459', 'M-LC-166460','M-LC-166458', 'M-LC-166460','M-LC-166459'};
         
        List<string> productNameList = new List<string>{'Managed Kona Site Defender Service', 'Kona Site Defender::Managed Kona Site Defender Service', 
            'Threat Update Review', 'Readiness and Response Service', 'Readiness and Response Service for Bot Manager', 'Premium Service and Support 2.0::Premium Service and Support 2.0', 
            'Premium Service and Support 2.0::Support Advocacy', 'Enterprise and Technical Advisory Services::Enterprise and Technical Advisory Services', 'Support Service Management Package', 
            'Service Management 2.0::Service Management', 'Security Optimization Assistance::Security Optimization Assistance', 'Security Optimization Assistance for Kona Site Defender', 
            'Security Optimization Assistance for Web Application Firewall', 'Security Optimization Assistance for Prolexic Routed', 'Security Optimization Assistance for Web Application Protector', 
            'Security Optimization Assistance for EAA/ETP', 'Security Optimization Assistance for Bot Manager', 'Advanced Service and Support', 'Plus Service and Support', 
            'Professional Services - Managed Integration', 'Integration::Managed Integration', 'Provisioning Services::Provisioning Services', 'Professional Services - Standard Integration', 
            'Integration::Standard Integration', 'Protect and Perform::Security Optimization Plus Service Management', 'Protect and Perform::Premium Plus Managed Kona', 
            'Protect and Perform::Managed Kona Plus Service Management', 'Protect and Perform::Premium Plus Security Optimization', 'Professional Services::Professional Services - Enterprise', 
            'Professional Services - Enterprise::Professional Services - Enterprise', 'Professional Services::PS Hours', 'Additional Professional Services', 'Professional Services - Optimization Services',
            'Professional Services - Packaged Solutions', 'Professional Services', 'Professional Services::PS Security Specialist Hours', 'Professional Services::Professional Services - Security', 
            'Professional Services - Enterprise::Professional Services - Security', 'Technical Advisory Service', 'Priority plus Technical Advisory Service', 'Professional Services::Technical Advisory Services',
            'Support - Named Enhanced Support Plus Technical Advisory Service', 'Technical Advisory Service::Technical Advisory Service', 'Technical Advisory Support', 'Premium Service and Support 3.0', 
            'Premium Service and Support 3.0::Off-Hour Configuration Assistance', 'Managed Security Service - Bot Manager Premier', 'Managed Security Service - Kona Site Defender', 'Managed Security Service - Bot Manager Premier & Kona Site Defender',
            'Managed Security Service - Bot Manager Premier', 'Managed Security Service - Bot Manager Premier & Kona Site Defender', 'Managed Security Service - Kona Site Defender'};

        
        
        if(productIdList.size() == productNameList.size()){
            List<SC_DD_Products__c> marketingProductList = new List<SC_DD_Products__c>();
            SC_DD_Products__c eachProduct;
            for(Integer i=0;i<productIdList.size(); i++){
                eachProduct =  new SC_DD_Products__c();
                eachProduct.Name = productIdList[i];
                eachProduct.Product_Name__c = productNameList[i];
                eachProduct.End_of_Life__c = False;
                marketingProductList.add(eachProduct);
            }
            if(marketingProductList.size() > 0)
                Insert marketingProductList;
        }
        else
            system.debug('Error : Miss match in the Count');
    }
        
     //non-GSS Marketing Products   
     public void createOtherMarketingProducts(){
        List<string> productIdList = new List<string>{  'M-LC-159891', 'M-LC-160618', 'M-LC-150335', 'M-LC-152189', 'M-LC-149717', 'M-LC-133443', 'M-LC-133649', '1-1RUSYB', 'M-LC-52279', 'M-LC-161242', 
            'M-LC-135091', 'M-LC-135297', 'M-LC-135503', 'M-LC-161200', 'M-LC-159905', 'M-LC-160650', 'M-LC-70819', 'M-LC-1036', 'M-LC-1037', 'M-LC-125821', 'M-LC-126027', 'M-LC-126233', 'M-LC-126439', 
            'M-LC-126645', 'M-LC-126851', 'M-LC-895', 'M-LC-134061', 'M-LC-157545', 'M-LC-136533', 'M-LC-63609', 'M-LC-165821', 'B-3-4LC2BU', 'M-LC-1049', 'M-LC-1184', 'M-LC-135915', 'M-LC-134473', 'M-LC-134679', 
            'M-LC-136739', 'M-LC-162045', 'M-LC-801', 'M-LC-802', 'M-LC-159892', 'M-LC-159904', 'M-LC-134885', 'M-LC-161405', 'M-LC-94509', 'M-LC-107899', 'M-LC-128087', 'M-LC-38271', 'M-LC-134267', 'B-3-6HAE63',
            'M-LC-1000', 'M-LC-1091', 'M-LC-110989', 'M-LC-113461', 'M-LC-1306', 'M-LC-1309', 'M-LC-1311', 'M-LC-1312', 'M-LC-1314', 'M-LC-1315', 'M-LC-1316', 'M-LC-1317', 'M-LC-1318', 'M-LC-1346', 'M-LC-137975', 
            'M-LC-138593', 'M-LC-138799', 'M-LC-139005', 'M-LC-139211', 'M-LC-1393', 'M-LC-139417', 'M-LC-139623', 'M-LC-140035', 'M-LC-140241', 'M-LC-140447', 'M-LC-140653', 'M-LC-141065', 'M-LC-141271', 'M-LC-141477', 
            'M-LC-141683', 'M-LC-141889', 'M-LC-142095', 'M-LC-142301', 'M-LC-144155', 'M-LC-144567', 'M-LC-159853', 'M-LC-159856', 'M-LC-159857', 'M-LC-159858', 'M-LC-159859', 'M-LC-159947', 'M-LC-159949', 'M-LC-159950', 
            'M-LC-159951', 'M-LC-159952', 'M-LC-159972', 'M-LC-160057', 'M-LC-160099', 'M-LC-160141', 'M-LC-160286', 'M-LC-160290', 'M-LC-160598', 'M-LC-160601', 'M-LC-160602', 'M-LC-160744', 'M-LC-160792', 'M-LC-160793', 
            'M-LC-161079', 'M-LC-161185', 'M-LC-161186', 'M-LC-161199', 'M-LC-161418', 'M-LC-161425', 'M-LC-161426', 'M-LC-161427', 'M-LC-161439', 'M-LC-161443', 'M-LC-161460', 'M-LC-161720', 'M-LC-162044', 'M-LC-58871', 
            'M-LC-68553', 'M-LC-71437', 'M-LC-804', 'M-LC-91831', 'M-LC-92037', 'M-LC-92449', 'M-LC-92655', 'M-LC-92861', 'M-LC-93067', 'M-LC-93273', 'M-LC-93479', 'M-LC-93685', 'M-LC-93891', 'M-LC-94097', 'M-LC-94715', 
            'M-LC-95127', 'M-LC-95333', 'M-LC-95539', 'M-LC-96363', 'M-LC-96569', 'M-LC-96775', 'M-LC-96981', 'M-LC-97187', 'M-LC-998', 'M-LC-999' };
                
       
        List<string> productNameList = new List<string>{'Octoshape::Extended Support - Premium', 'Broadcast Operations Control Center', 'Aura MCDN::Network Installation Fee', 
            'Aura Professional Services', 'Aura::Aura Enhanced Support', 'Akamai University Customer Training - Classroom', 'Customer Training - On-Site Training', 'Standard Support', 
            'Aura Support::Aura Enhanced Support', 'CloudTest On Demand', 'Live Event Support with Site Analyzer::Live Event Support with Site Analyzer',
            'Live Event Support with Stream Analyzer::Live Event Support with Stream Analyzer', 'On Call Event Support::On Call Event Support', 'Live Streaming Event Support:: PS Hours', 
            'Guided Delivery Service::Guided Delivery Service', 'Managed Delivery Service', 'Kona Third Party Management Access - IBM Managed Security Services', 'Akamai Media Player - Flash', 
            'Media Player Maintenance - Flash', 'Adaptive Media Player::Adaptive Media Player', 'Adaptive Media Player::Web - Standard', 'Adaptive Media Player::Web - Premier', 
            'Adaptive Media Player::Devices - Standard', 'Adaptive Media Player::Devices - Premier', 'AdaptiveMediaPlayer::Devices - Android SDK', 'Professional Services - Mobile Services',
            'Named Enhanced Support::Named Enhanced Support', 'Named Enhanced Support Plus Service Management', 'Named Enhanced Support Plus Technical Advisory Service', 
            'Support - Named Enhanced Support Plus Technical Advisory Service', 'Premium Service and Support 3.0 - Tier 3', 'Support - Priority Support Package', 'Support - Priority plus WAA Service Management', 
            'Priority plus Technical Advisory Service', 'Professional Services - Enterprise::Professional Services - Enterprise', 'Integration::Standard Integration', 'Integration::Managed Integration', 
            'Integration::Emergency Integration', 'Kona Site Defender plus DSA', 'Professional Services - Standard Integration', 'Professional Services - Managed Integration', 'Octoshape::Professional Services', 
            'Professional Services - Enterprise::Professional Services - Security', 'Integration::Self-Service Integration', 'Professional Services::SOASTA Legacy', 'Provisioning Services::Provisioning Services', 
            'Prolexic Routed Primary Location::On-demand Option', 'Service Management 2.0::Rule Update Service', 'Rule Update Service', 'Technical Advisory Service::Technical Advisory Service', 'AES Platform Fee', 
            'DDoS Fee Protection for WAA', 'Akamai DDoS Defender', 'Prolexic Connect::Additional Protected Subnets (per block of 8 x /24 subnets)', 'Protect and Perform Kona Site Defender Ion Premier', 
            'Kona Site Defender - Legacy', 'Kona Site Defender::Mobile Detection and Redirect', 'Kona Site Defender::Secure Delivery', 'Kona Site Defender::Secure Delivery::SSL Network Access - 3rd Party Certificate', 
            'Kona Site Defender::Secure Delivery::SSL Network Access - EV SAN', 'Kona Site Defender::Secure Delivery::SSL Network Access - Extended Validation', 'Kona Site Defender::Secure Delivery::SSL Network Access - SAN',
            'Kona Site Defender::Secure Delivery::SSL Network Access - Single Hostname', 'Kona Site Defender::Secure Delivery::SSL Network Access - Wildcard', 'Kona Site Defender::DDoS Fee Protection - Capped Burst Fee', 
            'Kona Site Defender::HTTPS Option', 'Kona Site Defender::HTTPS Option::SSL Network Access - Single Hostname', 'Kona Site Defender::HTTPS Option::SSL Network Access - Extended Validation', 
            'Kona Site Defender::HTTPS Option:SSL Network Access - Wildcard', 'Kona Site Defender::HTTPS Option::SSL Network Access - SAN', 'Protect and Perform - Kona Site Defender and Terra Alta', 
            'Kona Site Defender::HTTPS Option::SSL Network Access - 3rd Party Certificate', 'Kona Site Defender::HTTPS Option::SSL Network Access - EV SAN', 'Kona Site Defender::Kona Site Defender', 
            'Prolexic Connect::Protected Subnets (per block of 8 x /24 subnets)', 'Prolexic Routed Additional Location::Protected Subnets (per block of 8 x /24 subnets)', 
            'Prolexic Routed Primary Location::Protected Subnets (per block of 8 x /24 subnets)', 'Prolexic Routed Additional Location::Application-based Monitoring and CPE Appliance', 
            'Prolexic Routed Additional Location::Prolexic Routed Disaster Recovery Site', 'Prolexic Routed Additional Location::Application Based Monitoring and SSL CPE Appliance', 
            'Prolexic Routed Additional Location::Flow-based Monitoring', 'Prolexic Routed Additional Location::Client Border Router', 'Prolexic Routed Additional Location', 'Prolexic Routed Primary Location::Client Border Router',
            'Kona DDoS Defender::Kona DDoS Defender', 'Kona DDoS Defender::DDoS Fee Protection Capped Burst Fee', 'Kona DDoS Defender::Enhanced TLS', 'Kona DDoS Defender::SSL Network Access - Wildcard',
            'Kona DDoS Defender::SSL Network Access - SAN', 'Kona DDoS Defender::SSL Network Access - 3rd Party Certificate', 'Kona DDoS Defender::SSL Network Access - EV SAN', 'KSD::SSL Network Access - Single Hostname - SNI', 
            'KSD::SSL Network Access - SAN - SNI', 'KSD::SSL Network Access - 3rd Party Certificate - SNI', 'KSD::SSL Network Access - DV - SAN', 'KSD::SSL Network Access - DV - SAN - SNI', 'KDD::SSL Network Access - DV - SAN', 
            'Octoshape::Extended Support - Monitoring', 'Services Bundled Solution::Services Bundled Solution', 'Octoshape::Infinite-Managed On-Premise - Software License Fee', 'Kona DDoS Defender::SSL Network Access - Wildcard SAN',
            'Kona Site Defender::HTTPS Option::SSL Network Access - Wildcard SAN', 'KSD::Kona Site Defender - 100 Mbps additional usage per unit', 'Prolexic Routed::Routed Primary Location - 100 Mbps additional usage per unit', 
            'Prolexic Routed::Routed Additional Location - 100 Mbps additional usage per unit', 'KSD::SSL Network Access - EV - SNI', 'Kona DDoS Defender - Sites::Kona DDoS Defender - Sites', 'Kona DDoS Defender - Policies::Kona DDoS Defender - Policies', 
            'Prolexic Proxy::Emergency Provisioning', 'Custom Bundled Services 1 ‚ÄìMLB', 'Custom Bundled Services 2 ‚Äì iHeart', 'Live Streaming Event Support::Live Streaming Event Support', 'Prolexic Routed Additional Location::Additional Protected Subnets (/24 or equivalent)',
            'Prolexic Routed Primary Location::Additional Protected Subnets (/16 or equivalent)', 'Prolexic Routed Primary Location::Additional Protected Subnets (/18 or equivalent)', 'Prolexic Routed Primary Location::Additional Protected Subnets (/20 or equivalent)',
            'Prolexic Routed::Prolexic Proxy for Routed', 'Prolexic Routed Additional Location::Additional Client Border Router', 'Prolexic Routed Primary Location::Additional Client Border Router', 'Prolexic Routed Primary Location::GRE Tunnels', 
            'Kona Site Defender plus Ion', 'Protect and Perform - Kona Site Defender and Aqua Ion SP Secure', 'Bundled Services', 'Protect and Perform with Kona Site Defender and Aqua Ion SP Secure', 'Professional Services - Event Services', 
            'Prolexic Routed Primary Location::Prolexic Routed Primary Location', 'Prolexic Routed Primary Location::Prolexic Routed Disaster Recovery Site', 'Prolexic Routed::Additional VIPs', 'Prolexic Routed::Additional Provisioned Client Border Router', 
            'Prolexic Routed Primary Location::Additional Protected Subnets (/24 or equivalent)', 'Prolexic Routed::SERT Services', 'Prolexic Routed Primary Location::Flow-based Monitoring', 'Prolexic Proxy::Prolexic Proxy', 
            'Prolexic Routed Primary Location::Application Based Monitoring and CPE Appliance', 'Prolexic Proxy::Additional VIPs', 'Prolexic Routed Primary Location::Application Based Monitoring and SSL CPE Appliance', 'Prolexic Proxy::Flow-based Monitoring',
            'Prolexic Routed with Connect::Prolexic Routed with Connect', 'Prolexic Routed with Connect::GTT - 1 Gbps Port to the Prolexic Connect', 'Prolexic Routed with Connect::GTT - 10 Gbps Port to the Prolexic Connect', 'Prolexic Connect::Flow-based Monitoring', 
            'Prolexic Connect::Application-based Monitoring and CPE Appliance', 'Prolexic Connect::Application-based Monitoring and SSL CPE Appliance', 'Prolexic Proxy::Application-based Monitoring and SSL CPE Appliance', 'Protect and Perform::Kona Site Defender and Terra Alta', 
            'DDoS Fee Protection for Site Accelerator', 'DDoS Fee Protection for Site Delivery' };
        
        
        if(productIdList.size() == productNameList.size()){
            List<SC_DD_Products__c> marketingProductList = new List<SC_DD_Products__c>();
            SC_DD_Products__c eachProduct;
            for(Integer i=0;i<productIdList.size(); i++){
                eachProduct =  new SC_DD_Products__c();
                eachProduct.Name = productIdList[i];
                eachProduct.Product_Name__c = productNameList[i];
                eachProduct.End_of_Life__c = False;
                marketingProductList.add(eachProduct);
            }
            if(marketingProductList.size() > 0)
                Insert marketingProductList;
                    
        }
       else
           system.debug('Error : Miss match in the Count');
    
        
    }
    
    //Product #1.1 - SOA -> Kona Site Defender
    Public void createSOA_KSD(){ 
            SC_DD_GSSServiceProduct__c SOA_KSD = new SC_DD_GSSServiceProduct__c();
            SOA_KSD.Name = 'SOA';
            SOA_KSD.Is_Active__c = True;
            SOA_KSD.Is_Service_Support_Product__c = True;
            SOA_KSD.LOE_API_Call_Required__c = False;
            SOA_KSD.Product_Type__c = 'Kona Site Defender';
            SOA_KSD.List_Price_Multiplicand__c = 0.07692307692;
            SOA_KSD.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SOA_KSD;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = SOA_KSD.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 24;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 24;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = SOA_KSD.Id;
            PkgCmp2.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp2.Min__c = 3;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 3;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = SOA_KSD.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 13;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp3);
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{4500.00, 5200.00, 28000.00, 100000.00, 28000.00, 3300.00, 35000.00, 150000.00, 18000.00, 480000.00, 15000.00, 5800.00, 34000.00, 16000.00, 5700.00, 4700000.00, 35000.00, 4500.00, 140000.00, 16000.00, 17000.00, 3000.00, 4500.00, 80000.00, 20000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SOA_KSD.Id;
                prdPricingList.add(prdPricing);
            }  
    }
    
    
    //Product #1.2 - SOA -> Web Appln Firewall
    Public void createSOA_WAF(){ 
            SC_DD_GSSServiceProduct__c SOA_WAF = new SC_DD_GSSServiceProduct__c();
            SOA_WAF.Name = 'SOA';
            SOA_WAF.Is_Active__c = True;
            SOA_WAF.Is_Service_Support_Product__c = True;
            SOA_WAF.LOE_API_Call_Required__c = False;
            SOA_WAF.Product_Type__c = 'Web Appln Firewall';
            SOA_WAF.List_Price_Multiplicand__c = 0.1492537313;
            SOA_WAF.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SOA_WAF;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = SOA_WAF.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 10;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 10;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
                        
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = SOA_WAF.Id;
            PkgCmp2.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp2.Min__c = 2;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 2;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = SOA_WAF.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 6.7;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp3);
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{2500.00, 2900.00, 15000.00, 57000.00, 15000.00, 1800.00, 19000.00, 83000.00, 9700.00, 270000.00, 8200.00, 3200.00, 19000.00, 8900.00, 3200.00, 2600000.00, 20000.00, 2500.00, 76000.00, 8800.00, 9200.00, 1700.00, 2500.00, 45000.00, 11000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i<currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SOA_WAF.Id;
                prdPricingList.add(prdPricing);
            }  
    }
    
    //Product #1.3 - SOA -> Bot Manager
    Public void createSOA_Bot(){ 
            SC_DD_GSSServiceProduct__c SOA_Bot = new SC_DD_GSSServiceProduct__c();
            SOA_Bot.Name = 'SOA';
            SOA_Bot.Is_Active__c = True;
            SOA_Bot.Is_Service_Support_Product__c = True;
            SOA_Bot.LOE_API_Call_Required__c = False;
            SOA_Bot.Product_Type__c = 'Bot Manager';
            SOA_Bot.List_Price_Multiplicand__c = 0.07692307692;
            SOA_Bot.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SOA_Bot;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = SOA_Bot.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 24;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 24;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = SOA_Bot.Id;
            PkgCmp2.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp2.Min__c = 3;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 3;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = SOA_Bot.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 13;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp3);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{4500.00, 5200.00, 28000.00, 100000.00, 28000.00, 3300.00, 35000.00, 150000.00, 18000.00, 480000.00, 15000.00, 5800.00, 34000.00, 16000.00, 5700.00, 4700000.00, 35000.00, 4500.00, 140000.00, 16000.00, 17000.00, 3000.00, 4500.00, 80000.00, 20000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SOA_Bot.Id;
                prdPricingList.add(prdPricing);
            }  
    }
    
    //Product #1.4 - SOA -> Prolexic
    Public void createSOA_Prolexic(){ 
            SC_DD_GSSServiceProduct__c SOA_Prolexic = new SC_DD_GSSServiceProduct__c();
            SOA_Prolexic.Name = 'SOA';
            SOA_Prolexic.Is_Active__c = True;
            SOA_Prolexic.Is_Service_Support_Product__c = True;
            SOA_Prolexic.LOE_API_Call_Required__c = False;
            SOA_Prolexic.Product_Type__c = 'Prolexic';
            SOA_Prolexic.List_Price_Multiplicand__c = 0.2127659574;
            SOA_Prolexic.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SOA_Prolexic;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = SOA_Prolexic.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 4;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 4;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = SOA_Prolexic.Id;
            PkgCmp2.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp2.Min__c = 2;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 2;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = SOA_Prolexic.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 4.7;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp3);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{1700.00, 2000.00, 10000.00, 39000.00, 10000.00, 1200.00, 13000.00, 57000.00, 6600.00, 180000.00, 5600.00, 2200.00, 13000.00, 6000.00, 2200.00, 1800000.00, 13000.00, 1700.00, 52000.00, 6000.00, 6200.00, 1100.00, 1700.00, 30000.00, 7600.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SOA_Prolexic.Id;
                prdPricingList.add(prdPricing);
            }  
    }
    
    //Product #1.5 - SOA -> EAA/ETP
    Public void createSOA_EAA(){ 
            SC_DD_GSSServiceProduct__c SOA_EAA = new SC_DD_GSSServiceProduct__c();
            SOA_EAA.Name = 'SOA';
            SOA_EAA.Is_Active__c = True;
            SOA_EAA.Is_Service_Support_Product__c = True;
            SOA_EAA.LOE_API_Call_Required__c = False;
            SOA_EAA.Product_Type__c = 'EAA/ETP';
            SOA_EAA.List_Price_Multiplicand__c = 0.07692307692;
            SOA_EAA.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SOA_EAA;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = SOA_EAA.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 8;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 24;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = SOA_EAA.Id;
            PkgCmp2.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp2.Min__c = 2;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 3;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = SOA_EAA.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 13;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp3);
        
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{4500.00, 5200.00, 28000.00, 100000.00, 28000.00, 3300.00, 35000.00, 150000.00, 18000.00, 480000.00, 15000.00, 5800.00, 34000.00, 16000.00, 5700.00, 4700000.00, 35000.00, 4500.00, 140000.00, 16000.00, 17000.00, 3000.00, 4500.00, 80000.00, 20000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SOA_EAA.Id;
                prdPricingList.add(prdPricing);
            }  
    }
    
    
    //Product #2 - SMP
    Public void createSMP(){
        SC_DD_GSSServiceProduct__c SMP = new SC_DD_GSSServiceProduct__c();
            SMP.Name = 'SMP';
            SMP.Is_Active__c = True;
            SMP.Is_Service_Support_Product__c = True;
            SMP.LOE_API_Call_Required__c = False;
            SMP.List_Price_Multiplicand__c = 0.1;
            SMP.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SMP;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = SMP.Id;
            PkgCmp1.Name = 'Configurations';
            PkgCmp1.Min__c = 0;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 2;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = SMP.Id;
            PkgCmp2.Name = 'PS Hours/Quarter';
            PkgCmp2.Min__c = 13;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 18;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = SMP.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 10;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${Configurations.Requested} *2) + (${PS Hours/Quarter.Requested} / 3)';
            pckCompList.add(PkgCmp3);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{3000.00, 3500.00, 18000.00, 69000.00, 18000.00, 2200.00, 23000.00, 100000.00, 12000.00, 320000.00, 9800.00, 3800.00, 22000.00, 11000.00, 3800.00, 3200000.00, 23000.00, 3000.00, 91000.00, 11000.00, 11000.00, 2000.00, 3000.00, 53000.00, 13000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SMP.Id;
                prdPricingList.add(prdPricing);
            }
        
    }
    
 
    
    //Product #3 - Premium 2.0
    Public void createPremium2(){
        SC_DD_GSSServiceProduct__c Premium2 = new SC_DD_GSSServiceProduct__c();
            Premium2.Name = 'Premium 2.0';
            Premium2.Is_Active__c = True;
            Premium2.Is_Service_Support_Product__c = True;
            Premium2.LOE_API_Call_Required__c = False;
            Premium2.List_Price_Multiplicand__c = 0.008375;
            Premium2.Computed_ESR_Formula__c = '(requestedPrice * 0.67) / requestedHours';
            Insert Premium2;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = Premium2.Id;
            PkgCmp1.Name = 'Support Unit';
            PkgCmp1.Min__c = 1;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 1;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = Premium2.Id;
            PkgCmp2.Name = 'Support Advocacy';
            PkgCmp2.Min__c = 25;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 25;
            PkgCmp2.Sequence__c = 2;
            PkgCmp2.Package_Hours_Formula__c = '${Support Advocacy.Standard} * ${Support Unit.Requested}';
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = Premium2.Id;
            PkgCmp3.Name = 'PS Hours';
            PkgCmp3.Min__c = 40;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 40;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = Premium2.Id;
            PkgCmp4.Name = 'Advisory Hours';
            PkgCmp4.Min__c = 15;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 15;
            PkgCmp4.Sequence__c = 4;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = Premium2.Id;
            PkgCmp5.Name = 'Computed Total Package Hours/Month';
            PkgCmp5.Min__c = 1;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 80;
            PkgCmp5.Sequence__c = 5;
            PkgCmp5.Package_Hours_Formula__c = '${Support Advocacy.Requested} + ${PS Hours.Requested} + ${Advisory Hours.Requested}';
            pckCompList.add(PkgCmp5);
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{30000.00, 35000.00, 180000.00, 690000.00, 180000.00, 22000.00, 230000.00, 1000000.00, 120000.00, 3200000.00, 98000.00, 38000.00, 220000.00, 110000.00, 38000.00, 32000000.00, 230000.00, 30000.00, 910000.00, 70000.00, 110000.00, 20000.00, 30000.00, 530000.00, 130000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = Premium2.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    
    //Product #4 - RRS   
    Public void createRRS(){
        SC_DD_GSSServiceProduct__c RRS = new SC_DD_GSSServiceProduct__c();
            RRS.Name = 'RRS';
            RRS.Is_Active__c = True;
            RRS.Is_Service_Support_Product__c = True;
            RRS.LOE_API_Call_Required__c = False;
            RRS.List_Price_Multiplicand__c = 0.07692307692;
            RRS.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert RRS;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = RRS.Id;
            PkgCmp1.Name = 'Security Config Assistance PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 24;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 24;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = RRS.Id;
            PkgCmp2.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp2.Min__c = 3;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 3;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = RRS.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 13;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${Security Config Assistance PS Hours (Hrs/quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp3);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{12000.00, 14000.00, 74000.00, 270000.00, 74000.00, 8800.00, 93000.00, 400000.00, 47000.00, 1300000.00, 39000.00, 15000.00, 90000.00, 42000.00, 15000.00, 13000000.00, 94000.00, 12000.00, 370000.00, 42000.00, 44000.00, 8000.00, 12000.00, 210000.00, 54000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = RRS.Id;
                prdPricingList.add(prdPricing);
            }
    }
    

    //Product #5 - PnP: Managed Kona & SMP
    Public void createPnPKonanSMP(){
        SC_DD_GSSServiceProduct__c PnPKonanSMP = new SC_DD_GSSServiceProduct__c();
            PnPKonanSMP.Name = 'PnP: Managed Kona & SMP';
            PnPKonanSMP.Is_Active__c = True;
            PnPKonanSMP.Is_Service_Support_Product__c = True;
            PnPKonanSMP.LOE_API_Call_Required__c = False;
            PnPKonanSMP.List_Price_Multiplicand__c = 0.0161987041;
            PnPKonanSMP.Computed_ESR_Formula__c = 'requestedPrice / (requestedHours + (250/12))';
            Insert PnPKonanSMP;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PnPKonanSMP.Id;
            PkgCmp1.Name = 'Policies';
            PkgCmp1.Min__c = 5;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 5;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);

            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PnPKonanSMP.Id;
            PkgCmp2.Name = 'PS Hours (Hrs/Quarter)';
            PkgCmp2.Min__c = 34;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 42;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);

            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = PnPKonanSMP.Id;
            PkgCmp3.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp3.Min__c = 5;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 5;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = PnPKonanSMP.Id;
            PkgCmp4.Name = 'Security Advocacy (Hrs/Year)';
            PkgCmp4.Min__c = 175;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 175;
            PkgCmp4.Sequence__c = 4;
            PkgCmp4.Package_Hours_Formula__c = '((${Policies.Requested} - ${Policies.Standard}) * 35 + ${Security Advocacy (Hrs/Year).Standard})';
            pckCompList.add(PkgCmp4);
            
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = PnPKonanSMP.Id;
            PkgCmp5.Name = 'Configurations';
            PkgCmp5.Min__c = 1;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 2;
            PkgCmp5.Sequence__c = 5;
            pckCompList.add(PkgCmp5);
        
            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = PnPKonanSMP.Id;
            PkgCmp6.Name = 'Computed Total Package Hours/Month';
            PkgCmp6.Min__c = 1;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 40.9;
            PkgCmp6.Sequence__c = 6;
            PkgCmp6.Package_Hours_Formula__c = '(${PS Hours (Hrs/Quarter).Requested} / 3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12) + (${Security Advocacy (Hrs/Year).Requested} / 12) + (${Configurations.Requested} * 2)';
            pckCompList.add(PkgCmp6);
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{18500.00, 21500.00, 113600.00, 423500.00, 113900.00, 13570.00, 143700.00, 616700.00, 72080.00, 1973000.00, 60510.00, 23690.00, 138000.00, 65520.00, 23600.00, 19520000.00, 144400.00, 18400.00, 563000.00, 65010.00, 67950.00, 12400.00, 18500.00, 329900.00, 83120.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PnPKonanSMP.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #6 - PnP: SOA & SMP
    Public void createPnPSOAnSMP(){
        SC_DD_GSSServiceProduct__c PnPSOAnSMP = new SC_DD_GSSServiceProduct__c();
            PnPSOAnSMP.Name = 'PnP: SOA & SMP';
            PnPSOAnSMP.Is_Active__c = True;
            PnPSOAnSMP.Is_Service_Support_Product__c = True;
            PnPSOAnSMP.LOE_API_Call_Required__c = False;
            PnPSOAnSMP.List_Price_Multiplicand__c = 0.04347826087 ;
            PnPSOAnSMP.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert PnPSOAnSMP;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PnPSOAnSMP.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/Quarter)';
            PkgCmp1.Min__c = 0;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 42;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PnPSOAnSMP.Id;
            PkgCmp2.Name = 'Configurations';
            PkgCmp2.Min__c = 0;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 2;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = PnPSOAnSMP.Id;
            PkgCmp3.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp3.Min__c = 0;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 3;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = PnPSOAnSMP.Id;
            PkgCmp4.Name = 'Computed Total Package Hours/Month';
            PkgCmp4.Min__c = 1;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 23;
            PkgCmp4.Sequence__c = 4;
            PkgCmp4.Package_Hours_Formula__c = '(${PS Hours (Hrs/Quarter).Requested} / 3) + (${Configurations.Requested} * 2) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12)';
            pckCompList.add(PkgCmp4);
            
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{6750.00, 7844.00, 41440.00, 154500.00, 41550.00, 4950.00, 52410.00, 225000.00, 26300.00, 720000.00, 22080.00, 8644.00, 50360.00, 23910.00, 8612.00, 7122000.00, 52670.00, 6712.00, 205400.00, 23720.00, 24790.00, 4523.00, 6750.00, 120400.00, 30330.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PnPSOAnSMP.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #7 - PnP: Premium 2.0 & Managed Kona  
    Public void createPnPPremiumnKona(){
        SC_DD_GSSServiceProduct__c PnPPremiumnKona = new SC_DD_GSSServiceProduct__c();
            PnPPremiumnKona.Name = 'PnP: Premium 2.0 & Managed Kona';
            PnPPremiumnKona.Is_Active__c = True;
            PnPPremiumnKona.Is_Service_Support_Product__c = True;
            PnPPremiumnKona.LOE_API_Call_Required__c = False;
            PnPPremiumnKona.List_Price_Multiplicand__c = 0.005971241171; //0.005973501577 
            PnPPremiumnKona.Computed_ESR_Formula__c = '(requestedPrice * 0.789) / (requestedHours + (250/12))';
            Insert PnPPremiumnKona;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp1.Name = 'Support Unit';
            PkgCmp1.Min__c = 0;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 1;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp2.Name = 'Policies';
            PkgCmp2.Min__c = 5;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 5;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp3.Name = 'PS Hours (Hrs/Quarter)';
            PkgCmp3.Min__c = 150;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 190;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp4.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp4.Min__c = 5;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 5;
            PkgCmp4.Sequence__c = 4;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp5.Name = 'Security Advocacy (Hrs/Year)';
            PkgCmp5.Min__c = 175;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 175;
            PkgCmp5.Sequence__c = 5;
            PkgCmp5.Package_Hours_Formula__c = '((${Policies.Requested} - ${Policies.Standard}) * 35 + ${Security Advocacy (Hrs/Year).Standard})';
            pckCompList.add(PkgCmp5);
        
            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp6.Name = 'Support Advocacy (Hrs/Year)';
            PkgCmp6.Min__c = 0;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 75;
            PkgCmp6.Sequence__c = 6;
            PkgCmp6.Package_Hours_Formula__c = '(${Support Advocacy (Hrs/Year).Standard} * ${Support Unit.Requested})';
            pckCompList.add(PkgCmp6);
        
            SC_DD_Package_Components__c PkgCmp7 = new SC_DD_Package_Components__c();
            PkgCmp7.GSS_Product__c = PnPPremiumnKona.Id;
            PkgCmp7.Name = 'Computed Total Package Hours/Month';
            PkgCmp7.Min__c = 1;
            PkgCmp7.Max__c = 9999;
            PkgCmp7.Standard__c = 111.25;
            PkgCmp7.Sequence__c = 7;
            PkgCmp7.Package_Hours_Formula__c = '(${PS Hours (Hrs/Quarter).Requested}/3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12) + (${Security Advocacy (Hrs/Year).Requested} / 12) + (${Support Advocacy (Hrs/Year).Requested} / 3)';
                                         pckCompList.add(PkgCmp7);
            
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{43000.00, 50000.00, 260000.00, 980000.00, 260000.00, 32000.00, 330000.00, 1400000.00, 170000.00, 4600000.00, 140000.00, 55000.00, 320000.00, 150000.00, 55000.00, 45000000.00, 340000.00, 43000.00, 1300000.00, 150000.00, 160000.00, 29000.00, 43000.00, 770000.00, 190000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PnPPremiumnKona.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    
    //Product #8 - PnP: Premium 2.0 & SOA 
    Public void createPnPPremiumnSOA(){
        SC_DD_GSSServiceProduct__c PnPPremiumnSOA = new SC_DD_GSSServiceProduct__c();
            PnPPremiumnSOA.Name = 'PnP: Premium 2.0 & SOA';
            PnPPremiumnSOA.Is_Active__c = True;
            PnPPremiumnSOA.Is_Service_Support_Product__c = True;
            PnPPremiumnSOA.LOE_API_Call_Required__c = False;
            PnPPremiumnSOA.List_Price_Multiplicand__c = 0.0074663909;
            PnPPremiumnSOA.Computed_ESR_Formula__c = '(requestedPrice * 0.722) / requestedHours';
            Insert PnPPremiumnSOA;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PnPPremiumnSOA.Id;
            PkgCmp1.Name = 'Support Unit';
            PkgCmp1.Min__c = 0;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 1;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);

            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PnPPremiumnSOA.Id;
            PkgCmp2.Name = 'PS Hours (Hrs/Quarter)';
            PkgCmp2.Min__c = 150;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 190;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);

            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = PnPPremiumnSOA.Id;
            PkgCmp3.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp3.Min__c = 5;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 5;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = PnPPremiumnSOA.Id;
            PkgCmp4.Name = 'Support Advocacy';
            PkgCmp4.Min__c = 0;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 75;
            PkgCmp4.Sequence__c = 4;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = PnPPremiumnSOA.Id;
            PkgCmp5.Name = 'Computed Total Package Hours/Month';
            PkgCmp5.Min__c = 1;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 96.7;
            PkgCmp5.Sequence__c = 5;
            PkgCmp5.Package_Hours_Formula__c = '(${PS Hours (Hrs/Quarter).Requested}/3) + (${Additional Threat Update Reviews (Yearly).Requested} *20/12) + (${Support Advocacy.Requested}/3)';
            pckCompList.add(PkgCmp5);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{31000.00, 36000.00, 190000.00, 710000.00, 190000.00, 23000.00, 240000.00, 1000000.00, 120000.00, 3300000.00, 100000.00, 40000.00, 230000.00, 110000.00, 40000.00, 33000000.00, 240000.00, 31000.00, 940000.00, 110000.00, 110000.00, 21000.00, 31000.00, 550000.00, 140000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PnPPremiumnSOA.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    
    //Product #9 - Managed Kona
    Public void createManagedKona(){
        SC_DD_GSSServiceProduct__c ManagedKona = new SC_DD_GSSServiceProduct__c();
            ManagedKona.Name = 'Managed Kona';
            ManagedKona.Is_Active__c = True;
            ManagedKona.Is_Service_Support_Product__c = True;
            ManagedKona.LOE_API_Call_Required__c = False;
            ManagedKona.List_Price_Multiplicand__c = 0.01918158568;
            ManagedKona.Computed_ESR_Formula__c = 'requestedPrice / (requestedHours + (250/12))';
            Insert ManagedKona;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = ManagedKona.Id;
            PkgCmp1.Name = 'Policies';
            PkgCmp1.Min__c = 5;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 5;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = ManagedKona.Id;
            PkgCmp2.Name = 'PS (Hours/Quarter)';
            PkgCmp2.Min__c = 25;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 25;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = ManagedKona.Id;
            PkgCmp3.Name = 'Additional Threat Update Reviews (Yearly)';
            PkgCmp3.Min__c = 5;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 5;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = ManagedKona.Id;
            PkgCmp4.Name = 'Security Advocacy';
            PkgCmp4.Min__c = 175;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 175;
            PkgCmp4.Sequence__c = 4;
            PkgCmp4.Package_Hours_Formula__c = '(((${Policies.Requested}) - (${Policies.Standard})) * 35 + (${Security Advocacy.Standard}))';
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = ManagedKona.Id;
            PkgCmp5.Name = 'Computed Total Package Hours/Month';
            PkgCmp5.Min__c = 1;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 31.3;
            PkgCmp5.Sequence__c = 5;
            PkgCmp5.Package_Hours_Formula__c = '(${PS (Hours/Quarter).Requested} /3) + (${Additional Threat Update Reviews (Yearly).Requested} * 20/12) + (${Security Advocacy.Requested} / 12)';
            pckCompList.add(PkgCmp5);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{17500.00, 20300.00, 107000.00, 401000.00, 108000.00, 12800.00, 136000.00, 583000.00, 68200.00, 1870000.00, 57200.00, 22400.00, 131000.00, 62000.00, 22300.00, 18500000.00, 137000.00, 17400.00, 533000.00, 61500.00, 64300.00, 11700.00, 17500.00, 312000.00, 78600.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = ManagedKona.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #10.1 - Standard Integration->Security Product
    Public void createSIServiceProduct(){
        SC_DD_GSSServiceProduct__c SIServiceProduct = new SC_DD_GSSServiceProduct__c();
            SIServiceProduct.Name = 'Standard Integration';
            SIServiceProduct.Is_Active__c = True;
            SIServiceProduct.Is_Service_Support_Product__c = True;
            SIServiceProduct.LOE_API_Call_Required__c = True;
            SIServiceProduct.Product_Type__c = 'Security Product';
            SIServiceProduct.List_Price_Multiplicand__c = 0.07692307692;
            SIServiceProduct.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SIServiceProduct;        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{4500.00, 5200.00, 28000.00, 100000.00, 28000.00, 3300.00, 35000.00, 150000.00, 18000.00, 480000.00, 15000.00, 5800.00, 34000.00, 16000.00, 5700.00, 4700000.00, 35000.00, 4500.00, 140000.00, 16000.00, 17000.00, 3000.00, 4500.00, 80000.00, 20000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SIServiceProduct.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    
    //Product #10.2 - Standard Integration->Non-Security Product
    Public void createSInonServiceProduct(){
        SC_DD_GSSServiceProduct__c SInonServiceProduct = new SC_DD_GSSServiceProduct__c();
            SInonServiceProduct.Name = 'Standard Integration';
            SInonServiceProduct.Is_Active__c = True;
            SInonServiceProduct.Is_Service_Support_Product__c = True;
            SInonServiceProduct.LOE_API_Call_Required__c = True;
            SInonServiceProduct.Product_Type__c = 'Non-Security Product';
            SInonServiceProduct.List_Price_Multiplicand__c = 0.1;
            SInonServiceProduct.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert SInonServiceProduct;         
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{3000.00, 3500.00, 18000.00, 69000.00, 18000.00, 2200.00, 23000.00, 100000.00, 12000.00, 320000.00, 9800.00, 3800.00, 22000.00, 11000.00, 3800.00, 3200000.00, 23000.00, 3000.00, 91000.00, 11000.00, 11000.00, 2000.00, 3000.00, 53000.00, 13000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = SInonServiceProduct.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #11.1 - Managed Integration->Security Product
    Public void createMIServiceProduct(){
        SC_DD_GSSServiceProduct__c MIServiceProduct = new SC_DD_GSSServiceProduct__c();
            MIServiceProduct.Name = 'Managed Integration';
            MIServiceProduct.Is_Active__c = True;
            MIServiceProduct.Is_Service_Support_Product__c = True;
            MIServiceProduct.LOE_API_Call_Required__c = True;
            MIServiceProduct.Product_Type__c = 'Security Product';
            MIServiceProduct.List_Price_Multiplicand__c = 0.07692307692;
            MIServiceProduct.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert MIServiceProduct;        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{4500.00, 5200.00, 28000.00, 100000.00, 28000.00, 3300.00, 35000.00, 150000.00, 18000.00, 480000.00, 15000.00, 5800.00, 34000.00, 16000.00, 5700.00, 4700000.00, 35000.00, 4500.00, 140000.00, 16000.00, 17000.00, 3000.00, 4500.00, 80000.00, 20000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = MIServiceProduct.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #11.2 - Managed Integration->Non-Security Product
    Public void createMInonServiceProduct(){
        SC_DD_GSSServiceProduct__c MInonServiceProduct = new SC_DD_GSSServiceProduct__c();
            MInonServiceProduct.Name = 'Managed Integration';
            MInonServiceProduct.Is_Active__c = True;
            MInonServiceProduct.Is_Service_Support_Product__c = True;
            MInonServiceProduct.LOE_API_Call_Required__c = True;
            MInonServiceProduct.Product_Type__c = 'Non-Security Product';
            MInonServiceProduct.List_Price_Multiplicand__c = 0.1;
            MInonServiceProduct.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert MInonServiceProduct;         
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{3000.00, 3500.00, 18000.00, 69000.00, 18000.00, 2200.00, 23000.00, 100000.00, 12000.00, 320000.00, 9800.00, 3800.00, 22000.00, 11000.00, 3800.00, 3200000.00, 23000.00, 3000.00, 91000.00, 11000.00, 11000.00, 2000.00, 3000.00, 53000.00, 13000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
               prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = MInonServiceProduct.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #12 - Advanced
    Public void createAdvanced(){
        SC_DD_GSSServiceProduct__c Advanced = new SC_DD_GSSServiceProduct__c();
            Advanced.Name = 'Advanced';
            Advanced.Is_Active__c = True;
            Advanced.Is_Service_Support_Product__c = True;
            Advanced.LOE_API_Call_Required__c = False;
            Advanced.List_Price_Multiplicand__c = 0.02822580645; 
            Advanced.Computed_ESR_Formula__c = '(requestedPrice * 0.7) / requestedHours';
            
            Insert Advanced;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = Advanced.Id;
            PkgCmp1.Name = 'Configs';
            PkgCmp1.Min__c = 3;
            PkgCmp1.Max__c = 10;
            PkgCmp1.Standard__c = 5;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = Advanced.Id;
            PkgCmp2.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp2.Min__c = 20;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 30;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = Advanced.Id;
            PkgCmp3.Name = 'Meetings (EM+SA)';
            PkgCmp3.Min__c = 0;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 1.67; 
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '${Meetings (EM+SA).Standard}';
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = Advanced.Id;
            PkgCmp4.Name = 'Analysis (PS)';
            PkgCmp4.Min__c = 0;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 0.5;
            PkgCmp4.Sequence__c = 4;
            PkgCmp4.Package_Hours_Formula__c = '${Analysis (PS).Standard}';
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = Advanced.Id;
            PkgCmp5.Name = 'Report Prep';
            PkgCmp5.Min__c = 1;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 4.7;
            PkgCmp5.Sequence__c = 5;
            PkgCmp5.Package_Hours_Formula__c = '${Configs.Requested} * 4.67 / ${Configs.Standard}';
            pckCompList.add(PkgCmp5);

            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = Advanced.Id;
            PkgCmp6.Name = 'Advisory Hours';
            PkgCmp6.Min__c = 1;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 8;
            PkgCmp6.Sequence__c = 6;
            PkgCmp6.Package_Hours_Formula__c = '${Advisory Hours.Standard}';
            pckCompList.add(PkgCmp6);

            SC_DD_Package_Components__c PkgCmp7 = new SC_DD_Package_Components__c();
            PkgCmp7.GSS_Product__c = Advanced.Id;
            PkgCmp7.Name = 'Add on';
            PkgCmp7.Min__c = 0;
            PkgCmp7.Max__c = 9999;
            PkgCmp7.Standard__c = 0;
            PkgCmp7.Sequence__c = 7;
            PkgCmp7.Package_Hours_Formula__c = '0';
            pckCompList.add(PkgCmp7);

            SC_DD_Package_Components__c PkgCmp8 = new SC_DD_Package_Components__c();
            PkgCmp8.GSS_Product__c = Advanced.Id;
            PkgCmp8.Name = 'Project Management';
            PkgCmp8.Min__c = 0;
            PkgCmp8.Max__c = 1;
            PkgCmp8.Standard__c = 0;
            PkgCmp8.Sequence__c = 8;
            pckCompList.add(PkgCmp8);

            SC_DD_Package_Components__c PkgCmp9 = new SC_DD_Package_Components__c();
            PkgCmp9.GSS_Product__c = Advanced.Id;
            PkgCmp9.Name = 'Computed Total Package Hours/Month';
            PkgCmp9.Min__c = 1;
            PkgCmp9.Max__c = 9999;
            PkgCmp9.Standard__c = 24.8; // check 24.87
            PkgCmp9.Sequence__c = 9;
            PkgCmp9.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested}/3) + ${Meetings (EM+SA).Requested} + ${Analysis (PS).Requested} + ${Report Prep.Requested} + ${Advisory Hours.Requested}';
            pckCompList.add(PkgCmp9);
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{12000.00, 13940.00, 73670.00, 274700.00, 73870.00, 8800.00, 93180.00, 400000.00, 46750.00, 1280000.00, 39250.00, 15370.00, 89530.00, 42500.00, 15310.00, 12660000.00, 93640.00, 11930.00, 365200.00, 42170.00, 44080.00, 8040.00, 12000.00, 214000.00, 53910.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = Advanced.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #13.1 - Plus->Standard Entitlements
    Public void createPlusSE(){
        SC_DD_GSSServiceProduct__c PlusIon = new SC_DD_GSSServiceProduct__c();
            PlusIon.Name = 'Plus';
            PlusIon.Product_Type__c = 'Standard Entitlements';
            PlusIon.Is_Active__c = True;
            PlusIon.Is_Service_Support_Product__c = True;
            PlusIon.LOE_API_Call_Required__c = False;
            PlusIon.List_Price_Multiplicand__c = 0.1;
            PlusIon.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert PlusIon;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PlusIon.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 15;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 18;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PlusIon.Id;
            PkgCmp2.Name = 'Health Check Configurations';
            PkgCmp2.Min__c = 1;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 3;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = PlusIon.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 10;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested}/3) + (${Health Check Configurations.Requested} * (2/3)) + 2';    
            pckCompList.add(PkgCmp3);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{3000.00, 3486.00, 18420.00, 68680.00, 18470.00, 2200.00, 23300.00, 100000.00, 11690.00, 320000.00, 9812.00, 3842.00, 22380.00, 10620.00, 3827.00, 3165000.00, 23410.00, 2983.00, 91300.00, 10540.00, 11020.00, 2010.00, 3000.00, 53490.00, 13480.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PlusIon.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #13.2 - Plus->Scaled down version for DSA + WAP
    Public void createPlusDSA(){
        SC_DD_GSSServiceProduct__c PlusDSA = new SC_DD_GSSServiceProduct__c();
            PlusDSA.Name = 'Plus';
            PlusDSA.Product_Type__c = 'Scaled down version for DSA + WAP';
            PlusDSA.Is_Active__c = True;
            PlusDSA.Is_Service_Support_Product__c = True;
            PlusDSA.LOE_API_Call_Required__c = False;
            PlusDSA.List_Price_Multiplicand__c = 0.2;
            PlusDSA.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert PlusDSA;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PlusDSA.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp1.Min__c = 13;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 15;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PlusDSA.Id;
            PkgCmp2.Name = 'Health Check Configurations';
            PkgCmp2.Min__c = 0;
            PkgCmp2.Max__c = 0;
            PkgCmp2.Standard__c = 0;
            PkgCmp2.Sequence__c = 2;
            PkgCmp2.Package_Hours_Formula__c = '0';
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = PlusDSA.Id;
            PkgCmp3.Name = 'Computed Total Package Hours/Month';
            PkgCmp3.Min__c = 1;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 5;
            PkgCmp3.Sequence__c = 3;
            PkgCmp3.Package_Hours_Formula__c = '(${PS Hours (Hrs/quarter).Requested}/3)';
            pckCompList.add(PkgCmp3);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{1545.00, 1809.00, 9360.00, 35380.00, 9410.00, 1144.00, 12020.00, 52600.00, 5900.00, 163700.00, 5072.00, 1982.00, 11490.00, 5520.00, 1967.00, 1635000.00, 12130.00, 1528.00, 47500.00, 5440.00, 5590.00, 1029.00, 1545.00, 0.00, 0.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PlusDSA.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #14 - TAS
    Public void createTAS(){
        SC_DD_GSSServiceProduct__c TAS = new SC_DD_GSSServiceProduct__c();
            TAS.Name = 'TAS';
            TAS.Is_Active__c = True;
            TAS.Is_Service_Support_Product__c = True;
            TAS.LOE_API_Call_Required__c = False;
            TAS.List_Price_Multiplicand__c = 0.0625;
            TAS.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert TAS;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = TAS.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/month)';
            PkgCmp1.Min__c = 16;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 16;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = TAS.Id;
            PkgCmp2.Name = 'Computed Total Package Hours/Month';
            PkgCmp2.Min__c = 16;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 16;
            PkgCmp2.Sequence__c = 2;
            PkgCmp2.Package_Hours_Formula__c = '(${PS Hours (Hrs/month).Requested})';
            pckCompList.add(PkgCmp2);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{6000.00, 7000.00, 37000.00, 140000.00, 37000.00, 4400.00, 47000.00, 200000.00, 23000.00, 640000.00, 20000.00, 7700.00, 45000.00, 21000.00, 7700.00, 6300000.00, 47000.00, 6000.00, 180000.00, 21000.00, 22000.00, 4000.00, 6000.00, 110000.00, 27000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = TAS.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #15 - PS - Enterprise
    Public void createPSEnterprise(){
        SC_DD_GSSServiceProduct__c PSEnterprise = new SC_DD_GSSServiceProduct__c();
            PSEnterprise.Name = 'PS - Enterprise';
            PSEnterprise.Is_Active__c = True;
            PSEnterprise.Is_Service_Support_Product__c = True;
            PSEnterprise.LOE_API_Call_Required__c = False;
            PSEnterprise.List_Price_Multiplicand__c = 1;
            PSEnterprise.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert PSEnterprise;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PSEnterprise.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/month)';
            PkgCmp1.Min__c = 1;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 1;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PSEnterprise.Id;
            PkgCmp2.Name = 'Computed Total Package Hours/Month';
            PkgCmp2.Min__c = 1;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 1;
            PkgCmp2.Sequence__c = 2;
            PkgCmp2.Package_Hours_Formula__c = '${PS Hours (Hrs/month).Requested}';
            pckCompList.add(PkgCmp2);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{350, 410, 2100.00, 8000.00, 2200.00, 230, 2700.00, 12000.00, 1400.00, 37000.00, 1100.00, 450, 2600.00, 1200.00, 450, 370000.00, 2700.00, 350, 11000.00, 1230.00, 1300.00, 230, 350, 6200.00, 1600.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PSEnterprise.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #16 - PS - Security
    Public void createPSSecurity(){
        SC_DD_GSSServiceProduct__c PSSecurity = new SC_DD_GSSServiceProduct__c();
            PSSecurity.Name = 'PS - Security';
            PSSecurity.Is_Active__c = True;
            PSSecurity.Is_Service_Support_Product__c = True;
            PSSecurity.LOE_API_Call_Required__c = False;
            PSSecurity.List_Price_Multiplicand__c = 1;
            PSSecurity.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert PSSecurity;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = PSSecurity.Id;
            PkgCmp1.Name = 'PS Hours (Hrs/month)';
            PkgCmp1.Min__c = 1;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 1;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = PSSecurity.Id;
            PkgCmp2.Name = 'Computed Total Package Hours/Month';
            PkgCmp2.Min__c = 1;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 1;
            PkgCmp2.Sequence__c = 2;
            PkgCmp2.Package_Hours_Formula__c = '${PS Hours (Hrs/month).Requested}';
            pckCompList.add(PkgCmp2);
        
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{350, 410, 2100.00, 8000.00, 2200.00, 230, 2700.00, 12000.00, 1400.00, 37000.00, 1100.00, 450, 2600.00, 1200.00, 450, 370000.00, 2700.00, 350, 11000.00, 1230.00, 1300.00, 230, 350, 6200.00, 1600.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = PSSecurity.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #17 - Premium 3.0
    Public void createPremium3(){
        List<SC_DD_Package_Components__c> pckCompList = new list<SC_DD_Package_Components__c>();
        SC_DD_GSSServiceProduct__c Premium3 = new SC_DD_GSSServiceProduct__c();
            Premium3.Name = 'Premium 3.0';
            Premium3.Is_Active__c = True;
            Premium3.Is_Service_Support_Product__c = True;
            Premium3.LOE_API_Call_Required__c = False;
            Premium3.List_Price_Multiplicand__c = 0.0119047619;
            Premium3.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert Premium3;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = Premium3.Id;
            PkgCmp1.Name = 'Proactive Monitored Configs ';
            PkgCmp1.Min__c = 20;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 20;
            PkgCmp1.Sequence__c = 1;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = Premium3.Id;
            PkgCmp2.Name = 'Support Advocacy (Hrs/quarter)';
            PkgCmp2.Min__c = 57;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 57;
            PkgCmp2.Sequence__c = 2;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = Premium3.Id;
            PkgCmp3.Name = 'PS Hours (Hrs/quarter)';
            PkgCmp3.Min__c = 60;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 120;
            PkgCmp3.Sequence__c = 3;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = Premium3.Id;
            PkgCmp4.Name = 'TAS (Hrs/quarter)';
            PkgCmp4.Min__c = 60;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 60;
            PkgCmp4.Sequence__c = 4;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = Premium3.Id;
            PkgCmp5.Name = 'Technical Business Assessment';
            PkgCmp5.Min__c = 1;
            PkgCmp5.Max__c = 12;
            PkgCmp5.Standard__c = 2;
            PkgCmp5.Sequence__c = 5;
            pckCompList.add(PkgCmp5);
        
            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = Premium3.Id;
            PkgCmp6.Name = 'Computed Total Package Hours/Month';
            PkgCmp6.Min__c = 84;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 84;
            PkgCmp6.Sequence__c = 6;
            PkgCmp6.Package_Hours_Formula__c = '(${Support Advocacy (Hrs/quarter).Requested}/3) + (${PS Hours (Hrs/quarter).Requested}/3) + (${TAS (Hrs/quarter).Requested}/3) + (${Technical Business Assessment.Requested}*2.5)';
            pckCompList.add(PkgCmp6);
        
            Insert pckCompList;
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{30000.00, 35000.00, 180000.00, 690000.00, 180000.00, 22000.00, 230000.00, 1000000.00, 120000.00, 3200000.00, 98000.00, 38000.00, 220000.00, 110000.00, 38000.00, 32000000.00, 230000.00, 30000.00, 910000.00, 110000.00, 110000.00, 20000.00, 30000.00, 530000.00, 130000.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = Premium3.Id;
                prdPricingList.add(prdPricing);
            }
        
    }
    
    
    //Product #18.1 - MSS -> KSD 
    Public void createMSSKSD(){
        List<SC_DD_Package_Components__c> pckCompList = new list<SC_DD_Package_Components__c>();
        SC_DD_GSSServiceProduct__c MSSKSD = new SC_DD_GSSServiceProduct__c();
            MSSKSD.Name = 'MSS';
            MSSKSD.Is_Active__c = True;
            MSSKSD.Is_Service_Support_Product__c = True;
            MSSKSD.LOE_API_Call_Required__c = False;
            MSSKSD.Product_Type__c = 'KSD';
            MSSKSD.List_Price_Multiplicand__c = 0.02105263158;
            MSSKSD.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert MSSKSD;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp9 = new SC_DD_Package_Components__c();
            PkgCmp9.GSS_Product__c = MSSKSD.Id;
            PkgCmp9.Name = 'Managed KSD Policies';
            PkgCmp9.Min__c = 5;
            PkgCmp9.Max__c = 9999;
            PkgCmp9.Standard__c = 5;
            PkgCmp9.Sequence__c = 1;
            PkgCmp9.Package_Hours_Formula__c = '5';
            pckCompList.add(PkgCmp9);
        
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = MSSKSD.Id;
            PkgCmp1.Name = 'Technical Services Review (Yearly)';
            PkgCmp1.Min__c = 5;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 5;
            PkgCmp1.Sequence__c = 2;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = MSSKSD.Id;
            PkgCmp2.Name = 'Monthly Solution Review (Yearly)';
            PkgCmp2.Min__c = 12;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 12;
            PkgCmp2.Sequence__c = 3;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = MSSKSD.Id;
            PkgCmp3.Name = 'Customer Business Review (Quarterly)';
            PkgCmp3.Min__c = 4;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 4;
            PkgCmp3.Sequence__c = 4;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = MSSKSD.Id;
            PkgCmp4.Name = 'Security Configuration Assistance (Quarterly)';
            PkgCmp4.Min__c = 0;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 4;
            PkgCmp4.Sequence__c = 5;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = MSSKSD.Id;
            PkgCmp5.Name = 'Managed Security Consultant (Weekly)';
            PkgCmp5.Min__c = 0;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 52;
            PkgCmp5.Sequence__c = 6;
            pckCompList.add(PkgCmp5);
        
            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = MSSKSD.Id;
            PkgCmp6.Name = 'Security Operations Center Support (KERT) (Monthly)';
            PkgCmp6.Min__c = 0;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 12;
            PkgCmp6.Sequence__c = 7;
            pckCompList.add(PkgCmp6);
        
            SC_DD_Package_Components__c PkgCmp7 = new SC_DD_Package_Components__c();
            PkgCmp7.GSS_Product__c = MSSKSD.Id;
            PkgCmp7.Name = 'Computed Total Package Hours/Month';
            PkgCmp7.Min__c = 47.5;
            PkgCmp7.Max__c = 9999;
            PkgCmp7.Standard__c = 47.5;
            PkgCmp7.Sequence__c = 8;
            PkgCmp7.Package_Hours_Formula__c = '${Technical Services Review (Yearly).Requested} * 0.83) + (${Monthly Solution Review (Yearly).Requested} * 0.25) + (${Customer Business Review (Quarterly).Requested} * 0.25) + (${Security Configuration Assistance (Quarterly).Requested} * 2.08) + (${Managed Security Consultant (Weekly).Requested} * 0.25) +  (${Security Operations Center Support (KERT) (Monthly).Requested} * 1.5)';
            pckCompList.add(PkgCmp7);
        
            Insert pckCompList;
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{20000.00, 23240.00, 122800.00, 457900.00, 123100.00, 14670.00, 155300.00, 666700.00, 77920.00, 2133000.00, 65410.00, 25610.00, 149200.00, 70830.00, 25520.00, 21100000.00, 156100.00, 19890.00, 608700.00, 70280.00, 73460.00, 13400.00, 20000.00, 356600.00, 89860.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = MSSKSD.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    
    //Product #18.2 - MSS -> BMP  
    Public void createMSSBMP(){
        List<SC_DD_Package_Components__c> pckCompList = new list<SC_DD_Package_Components__c>();
        SC_DD_GSSServiceProduct__c MSSBMP = new SC_DD_GSSServiceProduct__c();
            MSSBMP.Name = 'MSS';
            MSSBMP.Is_Active__c = True;
            MSSBMP.Is_Service_Support_Product__c = True;
            MSSBMP.LOE_API_Call_Required__c = False;
            MSSBMP.Product_Type__c = 'BMP';
            MSSBMP.List_Price_Multiplicand__c = 0.01155134573;
            MSSBMP.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert MSSBMP;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp9 = new SC_DD_Package_Components__c();
            PkgCmp9.GSS_Product__c = MSSBMP.Id;
            PkgCmp9.Name = 'Managed BMP Endpoints';
            PkgCmp9.Min__c = 10;
            PkgCmp9.Max__c = 9999;
            PkgCmp9.Standard__c = 10;
            PkgCmp9.Sequence__c = 1;
            PkgCmp9.Package_Hours_Formula__c = '10';
            pckCompList.add(PkgCmp9);
            
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = MSSBMP.Id;
            PkgCmp1.Name = 'Technical Services Review (Yearly)';
            PkgCmp1.Min__c = 10;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 10;
            PkgCmp1.Sequence__c = 2;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = MSSBMP.Id;
            PkgCmp2.Name = 'Monthly Solution Review (Yearly)';
            PkgCmp2.Min__c = 12;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 12;
            PkgCmp2.Sequence__c = 3;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = MSSBMP.Id;
            PkgCmp3.Name = 'Customer Business Review (Quarterly)';
            PkgCmp3.Min__c = 4;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 4;
            PkgCmp3.Sequence__c = 4;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = MSSBMP.Id;
            PkgCmp4.Name = 'Security Configuration Assistance (Quarterly)';
            PkgCmp4.Min__c = 0;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 4;
            PkgCmp4.Sequence__c = 5;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = MSSBMP.Id;
            PkgCmp5.Name = 'Escalation Management (Quarterly)';
            PkgCmp5.Min__c = 0;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 4;
            PkgCmp5.Sequence__c = 6;
            PkgCmp5.Package_Hours_Formula__c = '(${Escalation Management (Quarterly).Standard})';
            pckCompList.add(PkgCmp5);
        
            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = MSSBMP.Id;
            PkgCmp6.Name = 'Managed Security Consultant (Weekly)';
            PkgCmp6.Min__c = 0;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 52;
            PkgCmp6.Sequence__c = 7;
            pckCompList.add(PkgCmp6);
        
            SC_DD_Package_Components__c PkgCmp7 = new SC_DD_Package_Components__c();
            PkgCmp7.GSS_Product__c = MSSBMP.Id;
            PkgCmp7.Name = 'Security Operations Center Support (KERT) (Monthly)';
            PkgCmp7.Min__c = 0;
            PkgCmp7.Max__c = 9999;
            PkgCmp7.Standard__c = 12;
            PkgCmp7.Sequence__c = 8;
            pckCompList.add(PkgCmp7);
        
            SC_DD_Package_Components__c PkgCmp8 = new SC_DD_Package_Components__c();
            PkgCmp8.GSS_Product__c = MSSBMP.Id;
            PkgCmp8.Name = 'Computed Total Package Hours/Month';
            PkgCmp8.Min__c = 86.57;
            PkgCmp8.Max__c = 9999;
            PkgCmp8.Standard__c = 86.57;
            PkgCmp8.Sequence__c = 9;
            PkgCmp8.Package_Hours_Formula__c = '(${Technical Services Review (Yearly).Requested} * 1.67) + (${Monthly Solution Review (Yearly).Requested} * 0.25) + (${Customer Business Review (Quarterly).Requested} * 0.25) + (${Security Configuration Assistance (Quarterly).Requested} * 1.85) + (${Managed Security Consultant (Weekly).Requested} * 2.90) +  (${Security Operations Center Support (KERT) (Monthly).Requested} * 0.25)';
            pckCompList.add(PkgCmp8);
        
            Insert pckCompList;
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{35000.00, 40670.00, 214900.00, 801300.00, 215500.00, 25670.00, 271800.00, 1167000.00, 136400.00, 3733000.00, 114500.00, 44820.00, 261100.00, 124000.00, 44650.00, 36930000.00, 273100.00, 34800.00, 1065000.00, 123000.00, 128600.00, 23450.00, 35000.00, 624100.00, 157200.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = MSSBMP.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    //Product #18.3 - MSS -> KSD + BMP
    Public void createMSSKSDnBMP(){
        List<SC_DD_Package_Components__c> pckCompList = new list<SC_DD_Package_Components__c>();
        SC_DD_GSSServiceProduct__c MSSKSDnBMP = new SC_DD_GSSServiceProduct__c();
            MSSKSDnBMP.Name = 'MSS';
            MSSKSDnBMP.Is_Active__c = True;
            MSSKSDnBMP.Is_Service_Support_Product__c = True;
            MSSKSDnBMP.LOE_API_Call_Required__c = False;
            MSSKSDnBMP.Product_Type__c = 'KSD + BMP';
            MSSKSDnBMP.List_Price_Multiplicand__c = 0.004199916002;
            MSSKSDnBMP.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
            Insert MSSKSDnBMP;
        
            //Package Components
            SC_DD_Package_Components__c PkgCmp10 = new SC_DD_Package_Components__c();
            PkgCmp10.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp10.Name = 'Managed KSD Policies';
            PkgCmp10.Min__c = 5;
            PkgCmp10.Max__c = 9999;
            PkgCmp10.Standard__c = 5;
            PkgCmp10.Sequence__c = 1;
            PkgCmp10.Package_Hours_Formula__c = '5';
            pckCompList.add(PkgCmp10);
            
            SC_DD_Package_Components__c PkgCmp9 = new SC_DD_Package_Components__c();
            PkgCmp9.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp9.Name = 'Managed BMP Endpoints';
            PkgCmp9.Min__c = 10;
            PkgCmp9.Max__c = 9999;
            PkgCmp9.Standard__c = 10;
            PkgCmp9.Sequence__c = 2;
            PkgCmp9.Package_Hours_Formula__c = '10';
            pckCompList.add(PkgCmp9);
        
            SC_DD_Package_Components__c PkgCmp1 = new SC_DD_Package_Components__c();
            PkgCmp1.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp1.Name = 'Technical Services Review (Yearly)';
            PkgCmp1.Min__c = 15;
            PkgCmp1.Max__c = 9999;
            PkgCmp1.Standard__c = 15;
            PkgCmp1.Sequence__c = 3;
            pckCompList.add(PkgCmp1);
            
            SC_DD_Package_Components__c PkgCmp2 = new SC_DD_Package_Components__c();
            PkgCmp2.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp2.Name = 'Monthly Solution Review (Yearly)';
            PkgCmp2.Min__c = 12;
            PkgCmp2.Max__c = 9999;
            PkgCmp2.Standard__c = 12;
            PkgCmp2.Sequence__c = 4;
            pckCompList.add(PkgCmp2);
        
            SC_DD_Package_Components__c PkgCmp3 = new SC_DD_Package_Components__c();
            PkgCmp3.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp3.Name = 'Customer Business Review (Quarterly)';
            PkgCmp3.Min__c = 4;
            PkgCmp3.Max__c = 9999;
            PkgCmp3.Standard__c = 4;
            PkgCmp3.Sequence__c = 5;
            pckCompList.add(PkgCmp3);
        
            SC_DD_Package_Components__c PkgCmp4 = new SC_DD_Package_Components__c();
            PkgCmp4.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp4.Name = 'Security Configuration Assistance (Quarterly)';
            PkgCmp4.Min__c = 0;
            PkgCmp4.Max__c = 9999;
            PkgCmp4.Standard__c = 4;
            PkgCmp4.Sequence__c = 6;
            pckCompList.add(PkgCmp4);
        
            SC_DD_Package_Components__c PkgCmp5 = new SC_DD_Package_Components__c();
            PkgCmp5.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp5.Name = 'Escalation Management (Quarterly)';
            PkgCmp5.Min__c = 0;
            PkgCmp5.Max__c = 9999;
            PkgCmp5.Standard__c = 4;
            PkgCmp5.Sequence__c = 7;
            PkgCmp5.Package_Hours_Formula__c = '(${Escalation Management (Quarterly).Standard})';
            pckCompList.add(PkgCmp5);
        
            SC_DD_Package_Components__c PkgCmp6 = new SC_DD_Package_Components__c();
            PkgCmp6.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp6.Name = 'Managed Security Consultant (Weekly)';
            PkgCmp6.Min__c = 0;
            PkgCmp6.Max__c = 9999;
            PkgCmp6.Standard__c = 52;
            PkgCmp6.Sequence__c = 8;
            pckCompList.add(PkgCmp6);
        
            SC_DD_Package_Components__c PkgCmp7 = new SC_DD_Package_Components__c();
            PkgCmp7.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp7.Name = 'Security Operations Center Support (KERT) (Monthly)';
            PkgCmp7.Min__c = 0;
            PkgCmp7.Max__c = 9999;
            PkgCmp7.Standard__c = 12;
            PkgCmp7.Sequence__c = 9;
            pckCompList.add(PkgCmp7);
        
            SC_DD_Package_Components__c PkgCmp8 = new SC_DD_Package_Components__c();
            PkgCmp8.GSS_Product__c = MSSKSDnBMP.Id;
            PkgCmp8.Name = 'Computed Total Package Hours/Month';
            PkgCmp8.Min__c = 123.90;
            PkgCmp8.Max__c = 9999;
            PkgCmp8.Standard__c = 123.90;
            PkgCmp8.Sequence__c = 10;
            PkgCmp8.Package_Hours_Formula__c = '(${Technical Services Review (Yearly).Requested} * 1.67) + (${Monthly Solution Review (Yearly).Requested} * 0.42) +     (${Customer Business Review (Quarterly).Requested} * 0.42) + (${Security Configuration Assistance (Quarterly).Requested} * 3.93) + (${Managed Security Consultant (Weekly).Requested} * 2.90) +  (${Security Operations Center Support (KERT) (Monthly).Requested} * 4.33)';
            pckCompList.add(PkgCmp8);
        
            Insert pckCompList;
            
            //Product Pricing
            List<String> currencyTypes = new List<String>{'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'India (INR)', 'Israel (ILS)', 'Japan (JPY)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'US (USD)', 'Mexico (MXN)', 'Brazil (BRL)'};
            List<Decimal> prices = new List<Decimal>{45000.00, 52290.00, 276300.00, 1030000.00, 277000.00, 33000.00, 349400.00, 1500000.00, 175300.00, 4800000.00, 147200.00, 57630.00, 335700.00, 159400.00, 57410.00, 47480000.00, 351100.00, 44750.00, 1370000.00, 158100.00, 165300.00, 30150.00, 45000.00, 802400.00, 202200.00};
            SC_DD_Product_Pricing__c prdPricing;
            for(integer i=0; i < currencyTypes.size(); i++){
                prdPricing = new  SC_DD_Product_Pricing__c();
                prdPricing.recordtypeId = prodPricingRecTypeId;
                prdPricing.Currency__c = currencyTypes[i];
                prdPricing.Local_List_Price__c = prices[i];
                prdPricing.GSS_Product__c = MSSKSDnBMP.Id;
                prdPricingList.add(prdPricing);
            }
    }
    
    
    //Other Products for Contract Mapping
    public void createOtherProducts(){
        
        SC_DD_GSSServiceProduct__c otherProduct;
        List<SC_DD_GSSServiceProduct__c> otherProductRecordList = new List<SC_DD_GSSServiceProduct__c>();
        List<String> otherProductList = new List<String>{'Akamai University','AkaTec', 'Broadcast Operations Control Center','Carrier Services','CloudTest On Demand','Enhanced SLA','Event Support','Guided Delivery Service','Managed Delivery Service','Managed Security Service - Legacy','Media Services','Named Enhanced Support','Named Enhanced Support + Service Management','Named Enhanced Support + Technical Advisory Service','Priority Support','Priority Support + Service Management','Professional Services - Enterprise','Professional Services - Octoshape','Professional Services - Self Service Integration','Professional Services - SOASTA','Prolexic Routed','Rule Update Service','WAF Service Management','Others'};
        
            for(Integer i=0; i<otherProductList.size(); i++){
                otherProduct = new SC_DD_GSSServiceProduct__c();
                otherProduct.Name = otherProductList[i];
                otherProduct.Is_Active__c = True;
                otherProduct.Is_Service_Support_Product__c = False;
                otherProduct.LOE_API_Call_Required__c = False;
                otherProductRecordList.add(otherProduct);  
            }
        Insert otherProductRecordList;
    }
    
    //Function to insert mapping records of products without product type
    public void createContractMapping1(){
        Id contractRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        Map<String, Id> productIDSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> contractMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c = null]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name, eachGSSProduct.Id);
        }
        
        for(SC_DD_Products__c  eachProduct : [SELECT Name, Id FROM SC_DD_Products__c]){
            productIDSFIdMap.put(eachProduct.Name, eachProduct.Id);
        }
        
        map<string, list<string>> productMapping = new map<string, list<string>>();
        productMapping.put('Managed Kona',new list<string>{'M-LC-139829','M-LC-62167','M-LC-132413'});
        productMapping.put('Premium 2.0',new list<string>{'M-LC-132825','M-LC-133031','M-LC-133237'});
        productMapping.put('SMP',new list<string>{'B-3-5SCZIN','M-LC-120877'});
        productMapping.put('RRS',new list<string>{'M-LC-161467', 'M-LC-161469'});
        productMapping.put('Advanced',new list<string>{'M-LC-165776'});
        productMapping.put('PS - Enterprise',new list<string>{'M-LC-38065','M-LC-135915','M-LC-135709','1-28210R','M-LC-803','M-LC-985','1-11B8A'});
        productMapping.put('PS - Security',new list<string>{'M-LC-136945','M-LC-37653','M-LC-159904'});
        productMapping.put('TAS',new list<string>{'M-LC-134267','M-LC-1184','M-LC-1183','M-LC-63609','M-LC-134267','M-LC-1051'});
        productMapping.put('Premium 3.0',new list<string>{'M-LC-165819','M-LC-165827'});
        
        productMapping.put('PnP: Managed Kona & SMP',new list<string>{'M-LC-162746'});
        productMapping.put('PnP: SOA & SMP',new list<string>{'M-LC-162752'});
        productMapping.put('PnP: Premium 2.0 & Managed Kona',new list<string>{'M-LC-162622'});
        productMapping.put('PnP: Premium 2.0 & SOA',new list<string>{'M-LC-162633'});
        
        //Other Products
        productMapping.put('Akamai University',new list<string>{'M-LC-133443','M-LC-133649'});
        productMapping.put('AkaTec',new list<string>{'1-1RUSYB','M-LC-159891'});
        productMapping.put('Broadcast Operations Control Center',new list<string>{'M-LC-160618'});
        productMapping.put('Carrier Services',new list<string>{'M-LC-150335', 'M-LC-152189', 'M-LC-149717','M-LC-52279' });
        productMapping.put('CloudTest On Demand',new list<string>{'M-LC-161242'});
        productMapping.put('Enhanced SLA',new list<string>{'M-LC-133855'});
        productMapping.put('Event Support',new list<string>{'M-LC-135091', 'M-LC-135297', 'M-LC-135503', 'M-LC-161200'});
        productMapping.put('Guided Delivery Service',new list<string>{'M-LC-159905'});
        productMapping.put('Managed Delivery Service',new list<string>{'M-LC-160650'});
        productMapping.put('Managed Security Service - Legacy',new list<string>{'M-LC-70819'});
        productMapping.put('Media Services',new list<string>{'M-LC-1036', 'M-LC-1037', 'M-LC-125821', 'M-LC-126027', 'M-LC-126233', 'M-LC-126439', 'M-LC-126645', 'M-LC-126851', 'M-LC-895'});
        productMapping.put('Named Enhanced Support',new list<string>{'M-LC-134061'});
        productMapping.put('Named Enhanced Support + Service Management',new list<string>{'M-LC-157545'});
        productMapping.put('Named Enhanced Support + Technical Advisory Service',new list<string>{'M-LC-136533'});
        //productMapping.put('Premium 3.0',new list<string>{'M-LC-165821'}); //Check
        productMapping.put('Priority Support',new list<string>{'B-3-4LC2BU'});
        productMapping.put('Priority Support + Service Management',new list<string>{'M-LC-1049'});
        productMapping.put('Professional Services - Enterprise',new list<string>{'M-LC-136739','M-LC-162045'});
        productMapping.put('Professional Services - Octoshape',new list<string>{'M-LC-159892'});
        productMapping.put('Professional Services - Self Service Integration',new list<string>{'M-LC-134885'});
        productMapping.put('Professional Services - SOASTA',new list<string>{'M-LC-161405'});
        productMapping.put('Prolexic Routed',new list<string>{'M-LC-107899'});
        productMapping.put('Rule Update Service',new list<string>{'M-LC-128087','M-LC-38271'});
        productMapping.put('WAF Service Management',new list<string>{'M-LC-1239'});
        productMapping.put('Others',new list<string>{'B-3-6HAE63','M-LC-1000','M-LC-1091','M-LC-110989','M-LC-113461','M-LC-1306','M-LC-1309','M-LC-1311','M-LC-1312','M-LC-1314','M-LC-1315','M-LC-1316','M-LC-1317','M-LC-1318','M-LC-1346','M-LC-137975','M-LC-138593','M-LC-138799','M-LC-139005','M-LC-139211','M-LC-1393','M-LC-139417','M-LC-139623','M-LC-140035','M-LC-140241','M-LC-140447','M-LC-140653','M-LC-141065','M-LC-141271','M-LC-141477','M-LC-141683','M-LC-141889','M-LC-142095','M-LC-142301','M-LC-144155','M-LC-144567','M-LC-159853','M-LC-159856','M-LC-159857','M-LC-159858','M-LC-159859','M-LC-159947','M-LC-159949','M-LC-159950','M-LC-159951','M-LC-159952','M-LC-159972','M-LC-160057','M-LC-160099','M-LC-160141','M-LC-160286','M-LC-160290','M-LC-160598','M-LC-160601','M-LC-160602','M-LC-160744','M-LC-160792','M-LC-160793','M-LC-161079','M-LC-161185','M-LC-161186','M-LC-161199','M-LC-161418','M-LC-161425','M-LC-161426','M-LC-161427','M-LC-161439','M-LC-161443','M-LC-161460','M-LC-161720','M-LC-162044','M-LC-58871','M-LC-68553','M-LC-71437','M-LC-804','M-LC-91831','M-LC-92037','M-LC-92449','M-LC-92655','M-LC-92861','M-LC-93067','M-LC-93273','M-LC-93479','M-LC-93685','M-LC-93891','M-LC-94097','M-LC-94715','M-LC-95127','M-LC-95333','M-LC-95539','M-LC-96363','M-LC-96569','M-LC-96775','M-LC-96981','M-LC-97187','M-LC-998','M-LC-999'});
        
        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMarketingProduct : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product__c = productIDSFIdMap.get(eachMarketingProduct);
                newMapping.RecordTypeId = contractRecordTypeId;
                contractMappingList.add(newMapping);
            }
        }
        
        Insert contractMappingList;
    }
    
    //Contract - Function to insert mapping records of products with product type
    public void createContractMapping2(){
        Id contractRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        Map<String, Id> productIDSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> contractMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c != null]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name + '-' +eachGSSProduct.Product_Type__c, eachGSSProduct.Id);
        }
        
        for(SC_DD_Products__c  eachProduct : [SELECT Name, Id FROM SC_DD_Products__c]){
            productIDSFIdMap.put(eachProduct.Name, eachProduct.Id);
        }
        
        map<string, list<string>> productMapping = new map<string, list<string>>();
        productMapping.put('Managed Integration-Security Product',new list<string>{'M-LC-802', 'M-LC-134679', 'M-LC-94509'});
        productMapping.put('Managed Integration-Non-Security Product',new list<string>{'M-LC-802', 'M-LC-134679', 'M-LC-94509'});
        productMapping.put('Standard Integration-Security Product',new list<string>{'M-LC-801','M-LC-134473'});
        productMapping.put('Standard Integration-Non-Security Product',new list<string>{'M-LC-801','M-LC-134473'});
        productMapping.put('SOA-Kona Site Defender',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-EAA/ETP',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-Web Appln Firewall',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-Bot Manager',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-Prolexic',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('Plus-Standard Entitlements',new list<string>{'M-LC-165777'});
        productMapping.put('Plus-Scaled down version for DSA + WAP',new list<string>{'M-LC-165777'});
        productMapping.put('MSS-KSD',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});
        productMapping.put('MSS-BMP',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});
        productMapping.put('MSS-KSD + BMP',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});


        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMarketingProduct : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product__c = productIDSFIdMap.get(eachMarketingProduct);
                newMapping.RecordTypeId = contractRecordTypeId;
                contractMappingList.add(newMapping);
            }
        }
        
        Insert contractMappingList;
        
    }
    
    //PS - Function to insert mapping records of products without product type
    public void createPSMapping1(){
        Id psRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Professional_Service').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        Map<String, Id> productIDSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> psMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c = null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name, eachGSSProduct.Id);
        }
        
        for(SC_DD_Products__c  eachProduct : [SELECT Name, Id FROM SC_DD_Products__c]){
            productIDSFIdMap.put(eachProduct.Name, eachProduct.Id);
        }
        
        map<string, list<string>> productMapping = new map<string, list<string>>();
        productMapping.put('Managed Kona',new list<string>{'M-LC-139829','M-LC-62167','M-LC-132413'});
        productMapping.put('Premium 2.0',new list<string>{'M-LC-132825','M-LC-133031','M-LC-133237'});
        productMapping.put('SMP',new list<string>{'B-3-5SCZIN','M-LC-120877'});
        productMapping.put('RRS',new list<string>{'M-LC-161467', 'M-LC-161469'});
        productMapping.put('Advanced',new list<string>{'M-LC-165776'});
        productMapping.put('PS - Enterprise',new list<string>{'M-LC-38065','M-LC-135915','M-LC-135709','1-28210R','M-LC-803','M-LC-985','1-11B8A'});
        productMapping.put('PS - Security',new list<string>{'M-LC-136945','M-LC-37653','M-LC-159904'});
        productMapping.put('TAS',new list<string>{'M-LC-134267','M-LC-1184','M-LC-1183','M-LC-63609','M-LC-134267','M-LC-1051'});
        productMapping.put('Premium 3.0',new list<string>{'M-LC-165819','M-LC-165827'});
        
        productMapping.put('PnP: Managed Kona & SMP',new list<string>{'M-LC-162746'});
        productMapping.put('PnP: SOA & SMP',new list<string>{'M-LC-162752'});
        productMapping.put('PnP: Premium 2.0 & Managed Kona',new list<string>{'M-LC-162622'});
        productMapping.put('PnP: Premium 2.0 & SOA',new list<string>{'M-LC-162633'});
        
        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMarketingProduct : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product__c = productIDSFIdMap.get(eachMarketingProduct);
                newMapping.RecordTypeId = psRecordTypeId;
                psMappingList.add(newMapping);
            }
        }
        
        Insert psMappingList;
        
    }
    
    //PS - Function to insert mapping records of products with product type
    public void createPSMapping2(){
        Id psRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Professional_Service').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        Map<String, Id> productIDSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> psMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c != null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name + '-' +eachGSSProduct.Product_Type__c, eachGSSProduct.Id);
        }
        
        for(SC_DD_Products__c  eachProduct : [SELECT Name, Id FROM SC_DD_Products__c]){
            productIDSFIdMap.put(eachProduct.Name, eachProduct.Id);
        }
        
        map<string, list<string>> productMapping = new map<string, list<string>>();
        productMapping.put('Managed Integration-Security Product',new list<string>{'M-LC-802', 'M-LC-134679', 'M-LC-94509'});
        productMapping.put('Managed Integration-Non-Security Product',new list<string>{'M-LC-802', 'M-LC-134679', 'M-LC-94509'});
        productMapping.put('Standard Integration-Security Product',new list<string>{'M-LC-801','M-LC-134473'});
        productMapping.put('Standard Integration-Non-Security Product',new list<string>{'M-LC-801','M-LC-134473'});
        productMapping.put('SOA-Kona Site Defender',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-EAA/ETP',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-Web Appln Firewall',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-Bot Manager',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('SOA-Prolexic',new list<string>{'M-LC-160425', 'M-LC-160426', 'M-LC-160427', 'M-LC-160429', 'M-LC-161083', 'M-LC-165944', 'M-LC-160428'});
        productMapping.put('Plus-Standard Entitlements',new list<string>{'M-LC-165777'});
        productMapping.put('Plus-Scaled down version for DSA + WAP',new list<string>{'M-LC-165777'});
        productMapping.put('MSS-KSD',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});
        productMapping.put('MSS-BMP',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});
        productMapping.put('MSS-KSD + BMP',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});


        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMarketingProduct : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product__c = productIDSFIdMap.get(eachMarketingProduct);
                newMapping.RecordTypeId = psRecordTypeId;
                psMappingList.add(newMapping);
            }
        }
        
        Insert psMappingList;
        
    }
    
    //AkaTec - Function to insert mapping records of Support Levels
    public void createAkaTecMapping(){
        Id akaTecRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Akatec').getRecordTypeId();
        
        List<SC_DD_Mapping__c> akaTecMappingList = new List<SC_DD_Mapping__c>();
        
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        List<String> supportLevelList = new List<String>{'Premium_2.0','Premium_2.0_Enhanced SLA','Premium_2.0_EnhancedSLA'};
        
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Name in ('Premium 2.0', 'PnP: Premium 2.0 & Managed Kona', 'PnP: Premium 2.0 & SOA')]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name, eachGSSProduct.Id);
        }
        
        SC_DD_Mapping__c newMapping;
        
        //Premium 2.0
        for(String eachProduct : gssproductNameSFIdMap.keySet()){
            for(String eachSupportLevel : supportLevelList){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Support_Level__c = eachSupportLevel;
                newMapping.RecordTypeId = akaTecRecordTypeId;
                akaTecMappingList.add(newMapping);
            }
        }
        
        //Plus
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Name in ('Plus')]){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = eachGSSProduct.Id;
            newMapping.Support_Level__c = 'Plus';
            newMapping.RecordTypeId = akaTecRecordTypeId;
            akaTecMappingList.add(newMapping);
        }
        
        //Advanced
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Name in ('Advanced')]){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = eachGSSProduct.Id;
            newMapping.Support_Level__c = 'Advanced';
            newMapping.RecordTypeId = akaTecRecordTypeId;
            akaTecMappingList.add(newMapping);
        }
        
        //Premium 3.0
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Name in ('Premium 3.0')]){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = eachGSSProduct.Id;
            newMapping.Support_Level__c = 'Premium_3.0';
            newMapping.RecordTypeId = akaTecRecordTypeId;
            akaTecMappingList.add(newMapping);
        }
        
        
        Insert akaTecMappingList;
    }
    
    
    //SOCC - Function to insert mapping records of Case Products
    public void createSOCCMapping(){
        Id soccRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('SOCC_Case_Product').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        
        List<SC_DD_Mapping__c> soccMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c = null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name, eachGSSProduct.Id);
        }
        
        
        map<string, string> productMapping = new map<string, string>();
        productMapping.put('Managed Kona','Managed Kona');
        productMapping.put('RRS','Readiness and Response Service');
        productMapping.put('PnP: Managed Kona & SMP','Managed Kona');
        productMapping.put('PnP: Premium 2.0 & Managed Kona','Managed Kona');
        
        
        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
            newMapping.Case_Product__c  = productMapping.get(eachProduct);
            newMapping.RecordTypeId = soccRecordTypeId;
            soccMappingList.add(newMapping);
        }
        
        //MSS
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Name in ('MSS')]){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = eachGSSProduct.Id;
            newMapping.Case_Product__c = 'Managed Services - BMP';
            newMapping.RecordTypeId = soccRecordTypeId;
            soccMappingList.add(newMapping);
        }
        
        
        Insert soccMappingList;
        
    }
    
    //Customer MRR - Function to insert mapping records of products without product type
    public void createCustomerMRRMapping1(){
        Id MRRRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Customer_MRR').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> mrrMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c = null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name, eachGSSProduct.Id);
        }
        
        
        map<string, string> productMapping = new map<string, string>();
        productMapping.put('Managed Kona','Managed Kona');
        productMapping.put('Premium 2.0','Premium Services and Support 2.0');
        productMapping.put('SMP','Service Management');
        productMapping.put('RRS','Readiness and Response Service');
        productMapping.put('Advanced','Advanced Service and Support');
        productMapping.put('PS - Security','Professional Services - Security');
        productMapping.put('PS - Enterprise','Professional Services - Security');
        productMapping.put('TAS','Technical Advisory Service');
        productMapping.put('Premium 3.0','Premium Services and Support 3.0');
        
        productMapping.put('PnP: Managed Kona & SMP','Protect and Perform Managed Kona + Service Management');
        productMapping.put('PnP: SOA & SMP','Protect and Perform Security Optimization Assistance + Service Management');
        productMapping.put('PnP: Premium 2.0 & Managed Kona','Protect and Perform Premium + Managed Kona');
        productMapping.put('PnP: Premium 2.0 & SOA','Protect and Perform Premium + Security Optimization Assistance');//Need to Update
        
        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
            newMapping.Customer_MRR_Name__c = productMapping.get(eachProduct);
            newMapping.RecordTypeId = MRRRecordTypeId;
            mrrMappingList.add(newMapping);
        }
        
        Insert mrrMappingList;
        
    }
    
    //Customer MRR - Function to insert mapping records of products with product type
    public void createCustomerMRRMapping2(){
        Id MRRRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Customer_MRR').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> mrrMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c != null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name + '-' +eachGSSProduct.Product_Type__c, eachGSSProduct.Id);
        }
        
                
        map<string, string> productMapping = new map<string, string>();
        productMapping.put('Managed Integration-Security Product','Professional Services - Integration');
        productMapping.put('Managed Integration-Non-Security Product','Professional Services - Integration');
        productMapping.put('Standard Integration-Security Product','Professional Services - Integration');
        productMapping.put('Standard Integration-Non-Security Product','Professional Services - Integration');
        productMapping.put('SOA-Kona Site Defender','Security Optimization Assistance');
        productMapping.put('SOA-EAA/ETP','Security Optimization Assistance');
        productMapping.put('SOA-Web Appln Firewall','Security Optimization Assistance');
        productMapping.put('SOA-Bot Manager','Security Optimization Assistance');
        productMapping.put('SOA-Prolexic','Security Optimization Assistance');
        productMapping.put('Plus-Standard Entitlements','Plus Service and Support');
        productMapping.put('Plus-Scaled down version for DSA + WAP','Plus Service and Support');
        

        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
            newMapping.Customer_MRR_Name__c = productMapping.get(eachProduct);
            newMapping.RecordTypeId = MRRRecordTypeId;
            mrrMappingList.add(newMapping);
        }
        
        Insert mrrMappingList;
        
    }
    
    //Customer MRR - Function to insert mapping records of products with multiple Customer MRR
    public void createCustomerMRRMapping3(){
        Id MRRRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Customer_MRR').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> mrrMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c != null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name + '-' +eachGSSProduct.Product_Type__c, eachGSSProduct.Id);
        }
        
                
        map<string, List<string>> productMapping = new map<string, List<string>>();
        productMapping.put('MSS-KSD',new list<string>{'Managed Security Service - Kona Site Defender', 'Managed Security Service - Bot Manager Premier','Managed Security Service - Bot Manager Premier & Kona Site Defender'});
        productMapping.put('MSS-BMP',new list<string>{'Managed Security Service - Kona Site Defender', 'Managed Security Service - Bot Manager Premier','Managed Security Service - Bot Manager Premier & Kona Site Defender'});
        productMapping.put('MSS-KSD + BMP',new list<string>{'Managed Security Service - Kona Site Defender', 'Managed Security Service - Bot Manager Premier','Managed Security Service - Bot Manager Premier & Kona Site Defender'});

        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMRRValue : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Customer_MRR_Name__c = eachMRRValue;
                newMapping.RecordTypeId = MRRRecordTypeId;
                mrrMappingList.add(newMapping);
            }
        }
        
        Insert mrrMappingList;
        
    }
    
    //Revenue - Function to insert mapping records of products without product type 
    public void createRevenueMapping1(){
        Id revenueRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Revenue').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> revenueMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c = null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name, eachGSSProduct.Id);
        }
                
        map<string, list<string>> productMapping = new map<string, list<string>>();
        productMapping.put('Managed Kona',new list<string>{'Managed Kona Site Defender Service'});
        productMapping.put('Premium 2.0',new list<string>{'Premium Services & Support 2.0 - Customer Support', 'Premium Services & Support 2.0 - PS Enterprise','Premium Services & Support 2.0 - Technical Advisory Services', 'Premium Services & Support 2.0 - Training'});
        productMapping.put('SMP',new list<string>{'Service Management 2.0' , 'Service Management Package', 'Web Application Accelerator Service Management Package', 'Enterprise Service Management' , 'Ion Service Management' , 'Alta Service Management', 'Dynamic Site Accelerator Service Management Package'});
        productMapping.put('RRS',new list<string>{'Readiness and Response Service'});
        productMapping.put('Advanced',new list<string>{'Advanced Service and Support - Technical Advisory Service','Advanced Service and Support - Training','Advanced Service and Support - PS Enterprise','Advanced Service and Support - Customer Support','Advanced Service and Support – Project Management'});
        productMapping.put('PS - Enterprise',new list<string>{'Professional Services - Enterprise'});
        productMapping.put('PS - Security',new list<string>{'Professional Services - Security'});
        productMapping.put('TAS',new list<string>{'Technical Advisory Services'});
        productMapping.put('Premium 3.0',new list<string>{  'Premium Service and Support 3.0 - Tier 1 Technical Advisory Service','Premium Service and Support 3.0 - Tier 1 PS Enterprise','Premium Service and Support 3.0 - Tier 1 Customer Support' 
                                                            ,'Premium Service and Support 3.0 - Tier 1 Training','Premium Service and Support 3.0 – PS Enterprise','Premium Service and Support 3.0 - Tier 2 Technical Advisory Service' 
                                                            ,'Premium Service and Support 3.0 - Tier 2 PS Enterprise','Premium Service and Support 3.0 - Tier 2 Customer Support','Premium Service and Support 3.0 - Tier 2 Training' 
                                                            ,'Premium Service and Support 3.0 – Customer Support','Premium Service and Support 3.0 - Tier 3 Customer Support','Premium Service and Support 3.0 - Tier 3 PS Enterprise' 
                                                            ,'Premium Service and Support 3.0 - Tier 3 Technical Advisory Service','Premium Service and Support 3.0 - Tier 3 Training'});
        
        
        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachProductGroup : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product_Group__c = eachProductGroup;
                newMapping.RecordTypeId = revenueRecordTypeId;
                revenueMappingList.add(newMapping);
            }
        }
        
        
        Insert revenueMappingList;
        
    }
    
    //Revenue - Function to insert mapping records of products with product type
    public void createRevenueMapping2(){
        Id revenueRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Revenue').getRecordTypeId();
        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> revenueMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c != null AND Is_Service_Support_Product__c = True]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name + '-' +eachGSSProduct.Product_Type__c, eachGSSProduct.Id);
        }
        
        map<string, list<string>> productMapping = new map<string, list<string>>();
        productMapping.put('Managed Integration-Security Product',new list<string>{'Professional Services - Managed Integration'});
        productMapping.put('Managed Integration-Non-Security Product',new list<string>{'Professional Services - Managed Integration'});
        productMapping.put('Standard Integration-Security Product',new list<string>{'Professional Services - Standard Integration'});
        productMapping.put('Standard Integration-Non-Security Product',new list<string>{'Professional Services - Standard Integration'});
        productMapping.put('SOA-Kona Site Defender',new list<string>{'Security Optimization Assistance'});
        productMapping.put('SOA-EAA/ETP',new list<string>{'Security Optimization Assistance'});
        productMapping.put('SOA-Web Appln Firewall',new list<string>{'Security Optimization Assistance'});
        productMapping.put('SOA-Bot Manager',new list<string>{'Security Optimization Assistance'});
        productMapping.put('SOA-Prolexic',new list<string>{'Security Optimization Assistance'});
        productMapping.put('Plus-ION+KSD / ION+WAP / DSA+KSD',new list<string>{'Plus Service and Support – Training','Plus Service and Support - PS Enterprise'});
        productMapping.put('Plus-DSA+WAP',new list<string>{'Plus Service and Support – Training','Plus Service and Support - PS Enterprise'});
        productMapping.put('MSS-KSD',new list<string>{'Managed Security Services -  BMP + KSD', 'Managed Security Services - BMP','Managed Security Services - KSD'});
        productMapping.put('MSS-BMP',new list<string>{'Managed Security Services -  BMP + KSD', 'Managed Security Services - BMP','Managed Security Services - KSD'});
        productMapping.put('MSS-KSD + BMP',new list<string>{'Managed Security Services -  BMP + KSD', 'Managed Security Services - BMP','Managed Security Services - KSD'});


        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachProductGroup : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product_Group__c = eachProductGroup;
                newMapping.RecordTypeId = revenueRecordTypeId;
                revenueMappingList.add(newMapping);
            }
        }
        
        Insert revenueMappingList;
        
    }
    
    
    
    public void createCustomSettings(){
        
        //Custom Setting : SC_DD_BatchJob_Config__c
        Insert new List<SC_DD_BatchJob_Config__c>{
                    new SC_DD_BatchJob_Config__c(Name = 'MRR', Sequence_No__c = 1, IS_ODI_Data__c = true, Status__c = 'New',
        Query__c = 'select Id,Status__c from SC_DD_Customer_MRR__c order by Status__c'),
        
                    new SC_DD_BatchJob_Config__c(Name = 'Revenue', Sequence_No__c = 2, IS_ODI_Data__c = true, Status__c = 'New',
        Query__c = 'select Id,Status__c from SC_DD_Revenue__c order by Status__c'),
        
                    new SC_DD_BatchJob_Config__c(Name = 'Cost', Sequence_No__c = 3, IS_ODI_Data__c = true, Status__c = 'New',
        Query__c = 'select Id,Status__c from SC_DD_Department_Cost__c order by Status__c', Is_Last_Record__c = true),
        
                    new SC_DD_BatchJob_Config__c(Name = 'PreDealData', Sequence_No__c = 11, Status__c = 'New',
        Query__c = 'select Id,Status__c from SC_DD_Customer_PreDeal_Data__c', IS_ODI_Data__c = false)
            };
                
        //Custom setting : Deal_Desk_Button_Visibility__c
        Upsert new List<Deal_Desk_Button_Visibility__c>{
            new Deal_Desk_Button_Visibility__c( Name='Red-SPO', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-DDA', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SLM/SLD', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SLD2', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-SLM/SLD', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Green-DDA', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SPO', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-SLD2', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SLM/SLD', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-SLD1', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SLD2', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SPO', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-DDA', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SLD1', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SLD1', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false )
        } name;
        
        Insert new List<SC_DD_Utility__c>{
                new SC_DD_Utility__c(Name = 'DD Setting', UI_Status__c  = 'New')
        };
    }
    
    Public void mssRelated(){
        List<string> productIdList = new List<string>{'M-LC-166458', 'M-LC-166459', 'M-LC-166460'};
        List<string> productNameList = new List<string>{'Managed Security Service - Bot Manager Premier', 'Managed Security Service - Kona Site Defender', 'Managed Security Service - Bot Manager Premier & Kona Site Defender'};
        if(productIdList.size() == productNameList.size()){
            List<SC_DD_Products__c> marketingProductList = new List<SC_DD_Products__c>();
            SC_DD_Products__c eachProduct;
            for(Integer i=0;i<productIdList.size(); i++){
                eachProduct =  new SC_DD_Products__c();
                eachProduct.Name = productIdList[i];
                eachProduct.Product_Name__c = productNameList[i];
                eachProduct.End_of_Life__c = False;
                marketingProductList.add(eachProduct);
            }
            if(marketingProductList.size() > 0)
                Insert marketingProductList;
        }
        else
            system.debug('Error : Miss match in the Count');    
        
    }
    
    public void deleteGSSProducts(){
        Delete [SELECT Id FROM SC_DD_GSSServiceProduct__c];   
    }
    
    public void deleteMarketingProducts(){
        Delete [SELECT Id FROM SC_DD_Products__c];   
    }
    
    public void deleteMapping(){
        Delete [SELECT Id FROM SC_DD_Mapping__c];   
    }

    Public void MSSProduct(){
        //Marketing Products
        List<string> productIdList = new List<string>{'M-LC-166458', 'M-LC-166460','M-LC-166459'};
        List<string> productNameList = new List<string>{'Managed Security Service - Bot Manager Premier', 'Managed Security Service - Bot Manager Premier & Kona Site Defender', 'Managed Security Service - Kona Site Defender'};

        if(productIdList.size() == productNameList.size()){
            List<SC_DD_Products__c> marketingProductList = new List<SC_DD_Products__c>();
            SC_DD_Products__c eachProduct;
            for(Integer i=0;i<productIdList.size(); i++){
                eachProduct =  new SC_DD_Products__c();
                eachProduct.Name = productIdList[i];
                eachProduct.Product_Name__c = productNameList[i];
                eachProduct.End_of_Life__c = False;
                marketingProductList.add(eachProduct);
            }
            if(marketingProductList.size() > 0)
                Insert marketingProductList;
        }
        else
            system.debug('Error : Miss match in the Count');


    //Contract Mapping
    Id contractRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
    Id psRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Professional_Service').getRecordTypeId();
    Id soccRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('SOCC_Case_Product').getRecordTypeId();
    Id revenueRecordTypeId = Schema.SObjectType.SC_DD_Mapping__c.getRecordTypeInfosByDeveloperName().get('Revenue').getRecordTypeId();



        Map<String, Id> gssproductNameSFIdMap = new Map<String, Id>();
        Map<String, Id> productIDSFIdMap = new Map<String, Id>();
        List<SC_DD_Mapping__c> contractMappingList = new List<SC_DD_Mapping__c>();
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Product_Type__c != null]){
            gssproductNameSFIdMap.put(eachGSSProduct.Name + '-' +eachGSSProduct.Product_Type__c, eachGSSProduct.Id);
        }
        
        for(SC_DD_Products__c  eachProduct : [SELECT Name, Id FROM SC_DD_Products__c]){
            productIDSFIdMap.put(eachProduct.Name, eachProduct.Id);
        }

        map<string, list<string>> productMapping = new map<string, list<string>>();

        productMapping.put('MSS-KSD',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});
        productMapping.put('MSS-BMP',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});
        productMapping.put('MSS-KSD + BMP',new list<string>{'M-LC-166458', 'M-LC-166459','M-LC-166460'});


        SC_DD_Mapping__c newMapping;
        
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMarketingProduct : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product__c = productIDSFIdMap.get(eachMarketingProduct);
                newMapping.RecordTypeId = contractRecordTypeId;
                contractMappingList.add(newMapping);
            }
        }
        
        Insert contractMappingList;
        List<SC_DD_Mapping__c> psMappingList = new List<SC_DD_Mapping__c>();
        for(String eachProduct : productMapping.keySet()){
            
            for(String eachMarketingProduct : productMapping.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product__c = productIDSFIdMap.get(eachMarketingProduct);
                newMapping.RecordTypeId = psRecordTypeId;
                psMappingList.add(newMapping);
            }
        }
        
        Insert psMappingList;

        List<SC_DD_Mapping__c> soccMappingList = new List<SC_DD_Mapping__c>();
        //MSS
        for(SC_DD_GSSServiceProduct__c eachGSSProduct : [SELECT Name, Id, Product_Type__c FROM SC_DD_GSSServiceProduct__c WHERE Name in ('MSS')]){
            newMapping = new SC_DD_Mapping__c();
            newMapping.Parent_GSS_Product__c = eachGSSProduct.Id;
            newMapping.Case_Product__c = 'Managed Services - BMP';
            newMapping.RecordTypeId = soccRecordTypeId;
            soccMappingList.add(newMapping);
        }
        
        
        Insert soccMappingList;
        
        List<SC_DD_Mapping__c> revenueMappingList = new List<SC_DD_Mapping__c>();
        
        map<string, list<string>> productMapping2 = new map<string, list<string>>();
        productMapping2.put('MSS-KSD',new list<string>{'Managed Security Services -  BMP + KSD', 'Managed Security Services - BMP','Managed Security Services - KSD'});
        productMapping2.put('MSS-BMP',new list<string>{'Managed Security Services -  BMP + KSD', 'Managed Security Services - BMP','Managed Security Services - KSD'});
        productMapping2.put('MSS-KSD + BMP',new list<string>{'Managed Security Services -  BMP + KSD', 'Managed Security Services - BMP','Managed Security Services - KSD'});

        for(String eachProduct : productMapping2.keySet()){
            
            for(String eachProductGroup : productMapping2.get(eachProduct)){
                newMapping = new SC_DD_Mapping__c();
                newMapping.Parent_GSS_Product__c = gssproductNameSFIdMap.get(eachProduct);
                newMapping.Product_Group__c = eachProductGroup;
                newMapping.RecordTypeId = revenueRecordTypeId;
                revenueMappingList.add(newMapping);
            }
        }
        
        Insert revenueMappingList;
    }  
    // ESESP-4301 Refactored Portfolio (SOA, RRS, MSS) 2.0
    public static void createSoatwoRrstwoMssTwoProds() {
        
        SC_DD_GSSServiceProduct__c soaTwo = new SC_DD_GSSServiceProduct__c(
            Name = 'SOA 2.0', 
            Is_Active__c = True,
            Is_Service_Support_Product__c = True,
            LOE_API_Call_Required__c = False,
            ESR_Green_Threshold__c = 0.95,
            ESR_Yellow_Threshold__c =  0.9,
            List_Price_Multiplicand__c = 0.08333333333,
            Computed_ESR_Formula__c = 'requestedPrice / requestedHours'
        );
        
        
        SC_DD_GSSServiceProduct__c rrsTwo = new SC_DD_GSSServiceProduct__c(
            Name = 'RRS 2.0', 
            Is_Active__c = True,
            Is_Service_Support_Product__c = True,
            LOE_API_Call_Required__c = False,
            ESR_Green_Threshold__c = 0.95,
            ESR_Yellow_Threshold__c =  0.9,
            List_Price_Multiplicand__c = 0.02941176471,
            Computed_ESR_Formula__c = 'requestedPrice / requestedHours'
        );
        
        SC_DD_GSSServiceProduct__c mssTwo = new SC_DD_GSSServiceProduct__c(
            Name = 'MSS 2.0', 
            Is_Active__c = True,
            Is_Service_Support_Product__c = True,
            LOE_API_Call_Required__c = False,
            ESR_Green_Threshold__c = 0.95,
            ESR_Yellow_Threshold__c =  0.9,
            List_Price_Multiplicand__c = 0.01249583472,
            Computed_ESR_Formula__c = 'requestedPrice / requestedHours',
            Computed_ESR_Override_Class__c = 'SC_DD_DealDeskCont.MSSTwoProductEsr'
        );
        
        // Insert Products
        insert new List<SC_DD_GSSServiceProduct__c>{ soaTwo, rrsTwo, mssTwo };
            
            
            // Insert Package Customisations
            
            List<SC_DD_Package_Components__c> pckCompList = new List<SC_DD_Package_Components__c>();
        //Package Components - SOA 2.0
        pckCompList.add(    
            new SC_DD_Package_Components__c(
                GSS_Product__c = soaTwo.Id,
                Name = 'Security Configuration Hours (Per Quarter)',
                Min__c = 12,
                Max__c = 9999,
                Standard__c = 24,
                Sequence__c = 1
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = soaTwo.Id,
                Name = 'Technical Security Reviews (Yearly)',
                Min__c = 2,
                Max__c = 9999,
                Standard__c = 3,
                Sequence__c = 2
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = soaTwo.Id,
                Name = 'Computed Total Package Hours/Month',
                Min__c = 1,
                Max__c = 9999,
                Standard__c = 12,
                Sequence__c = 3,
                Package_Hours_Formula__c = '(${Security Configuration Hours (Per Quarter).Requested} / 3) + (${Technical Security Reviews (Yearly).Requested} * 16/12)'
            ));
        
        //Package Components - RRS 2.0
        pckCompList.add(    
            new SC_DD_Package_Components__c(
                GSS_Product__c = rrsTwo.Id,
                Name = 'Security Config Assistance PS Hours (Hrs/quarter)',
                Min__c = 24,
                Max__c = 9999,
                Standard__c = 24,
                Sequence__c = 1
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = rrsTwo.Id,
                Name = 'Threat Reviews (Yearly)',
                Min__c = 3,
                Max__c = 9999,
                Standard__c = 3,
                Sequence__c = 2
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = rrsTwo.Id,
                Name = 'SOCC (Yearly)',
                Min__c = 1,
                Max__c = 9999,
                Standard__c = 1,
                Sequence__c = 3,
                Package_Hours_Formula__c = '${SOCC (Yearly).Standard}'
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = rrsTwo.Id,
                Name = 'Managed Security Consultant (Quarterly)',
                Min__c = 20,
                Max__c = 9999,
                Standard__c = 20,
                Sequence__c = 4,
                Package_Hours_Formula__c = '${Managed Security Consultant (Quarterly).Standard}'
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = rrsTwo.Id,
                Name = 'Additional SOCC Unit (Yearly)',
                Min__c = 0,
                Max__c = 9999,
                Standard__c = 0,
                Sequence__c = 5
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = rrsTwo.Id,
                Name = 'Computed Total Package Hours/Month',
                Min__c = 1,
                Max__c = 9999,
                Standard__c = 34,
                Sequence__c = 6,
                Package_Hours_Formula__c = '(${Security Config Assistance PS Hours (Hrs/quarter).Requested} * 4 / 12) + (${Threat Reviews (Yearly).Requested} * 16/12) + (${SOCC (Yearly).Requested} * 184/12) + (${Managed Security Consultant (Quarterly).Requested} * 4/12) + (${Additional SOCC Unit (Yearly).Requested} * 46/12)'
            ));
        
        //Package Components - MSS 2.0
        pckCompList.add(    
            new SC_DD_Package_Components__c(
                GSS_Product__c = mssTwo.Id,
                Name = 'Security Configuration Hours (Quarterly)',
                Min__c = 12,
                Max__c = 9999,
                Standard__c = 67,
                Sequence__c = 1
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = mssTwo.Id,
                Name = 'Threat Reviews (Annually)',
                Min__c = 2,
                Max__c = 9999,
                Standard__c = 2,
                Sequence__c = 2
            ));
        pckCompList.add(
            new SC_DD_Package_Components__c(
                GSS_Product__c = mssTwo.Id,
                Name = 'SOCC (Yearly)',
                Min__c = 1,
                Max__c = 9999,
                Standard__c = 1,
                Sequence__c = 3,
                Package_Hours_Formula__c = '${SOCC (Yearly).Standard}'
            ));
        pckCompList.add( new SC_DD_Package_Components__c(
            GSS_Product__c = mssTwo.Id,
            Name = 'Managed Security Consultant (Quarterly)',
            Min__c = 1,
            Max__c = 9999,
            Standard__c = 51,
            Sequence__c = 4,
            Package_Hours_Formula__c = '${Managed Security Consultant (Quarterly).Standard}'
        ));
        pckCompList.add( new SC_DD_Package_Components__c(
            GSS_Product__c = mssTwo.Id,
            Name = 'SOCC Unit (Yearly)',
            Min__c = 0,
            Max__c = 9999,
            Standard__c = 0,
            Sequence__c = 5
        ));
        pckCompList.add( new SC_DD_Package_Components__c(
            GSS_Product__c = mssTwo.Id,
            Name = 'Managed Policies (Monthly)',
            Min__c = 0,
            Max__c = 9999,
            Standard__c = 3,
            Sequence__c = 6
        ));
        pckCompList.add( new SC_DD_Package_Components__c(
            GSS_Product__c = mssTwo.Id,
            Name = 'Managed Endpoints (Monthly)',
            Min__c = 0,
            Max__c = 9999,
            Standard__c = 5,
            Sequence__c = 7
        ));
        pckCompList.add( new SC_DD_Package_Components__c(
            GSS_Product__c = mssTwo.Id,
            Name = 'Managed PI Configurations (Monthly)',
            Min__c = 0,
            Max__c = 9999,
            Standard__c = 3,
            Sequence__c = 8
        ));
        pckCompList.add( new SC_DD_Package_Components__c(
            GSS_Product__c = mssTwo.Id,
            Name = 'Computed Total Package Hours/Month',
            Min__c = 1,
            Max__c = 9999,
            Standard__c = 80.0266666667,
            Sequence__c = 9,
            Package_Hours_Formula__c = '(${Security Configuration Hours (Quarterly).Requested} * 4 * 1.14 / 12) + (${Threat Reviews (Annually).Requested} * 16 * 1.22 /12) + (${SOCC (Yearly).Requested} * 184/12) + (${Managed Security Consultant (Quarterly).Requested} * 4/12) + (${SOCC Unit (Yearly).Requested} * 46 * 0.76 /12)+ (${Managed Policies (Monthly).Requested} * 0.7) + (${Managed Endpoints (Monthly).Requested} * 1.9 * 1.54) + (${Managed PI Configurations (Monthly).Requested} * 0.75)'
            // Package_Hours_Formula__c = '(${Security Configuration Hours (Quarterly).Requested} * 3 * 1.14 / 12) + (${Threat Reviews (Annually).Requested} * 1.16 * 1.22 /12) + (${SOCC (Yearly).Requested} * 184/12) + (${Managed Security Consultant (Quarterly).Requested} * 4/12) + (${SOCC Unit (Yearly).Requested} * 46 * 0.76 /12)+ (${Managed Policies (Monthly).Requested} * 0.7) + (${Managed Endpoints (Monthly).Requested} * 1.9 * 1.54) + (${Managed PI Configurations (Monthly).Requested} * 0.75)'
        ));
        
        insert pckCompList;
        
        // Insert Pricing
        List<String> currencyTypes = new List<String>{'US (USD)', 'JAPAN (JPY)', 'India (INR)', 'Australia (AUD)', 'Canada (CAD)', 'China (CNY)', 'Czech Republic (CZK)', 'Denmark (DKK)', 'EuroZone (EUR)', 'Hong Kong (HKD)', 'Israel (ILS)', 'Malaysia (MYR)', 'New Zealand(NZD)', 'Norway(NOK)', 'Poland (PLN)', 'Singapore (SGD)', 'South Korea (KRW)', 'Sweden (SEK)', 'Switzerland (CHF)', 'Taiwan (TWD)', 'Turkey (TRY)', 'UAE (AED)', 'United Kingdom (GBP)', 'Mexico (MXN)', 'Brazil (BRL)'};
            
        List<Decimal> mssTwoPrices = new List<Decimal>{24600, 2630000, 820000, 24600, 28600, 152000, 564000, 152000, 18100, 192000, 95900, 80500, 31600, 184000, 87200, 31400, 26000000, 192000, 24500, 749000, 86500, 90400, 16500, 0, 0};
                
        List<Decimal> rssTwoPrices = new List<Decimal>{10000, 1070000, 334000,  10000, 11700, 61400, 229000, 61600, 7340, 77700, 39000, 32800, 12900, 74700, 35500, 12800, 10600000, 78100, 9950, 305000, 35200, 36800, 6700, 0, 0};
                    
        List<Decimal> soaTwoPrices = new List<Decimal>{4000, 427000, 134000, 4000, 4650, 24600, 91600, 24700, 2940, 31100, 15600, 13100, 5130, 29900, 14200, 5110, 4230000, 31300, 3980, 122000, 14100, 14700, 2680, 0, 0};
                        
        Id prodPricingRecTypeId = Schema.SObjectType.SC_DD_Product_Pricing__c.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        
        List<SC_DD_Product_Pricing__c> prodPricingList = new List<SC_DD_Product_Pricing__c>();
        
        for(integer i=0; i < currencyTypes.size(); i++){
            prodPricingList.add(new  SC_DD_Product_Pricing__c(
                recordtypeId = prodPricingRecTypeId,
                Currency__c = currencyTypes[i],
                Local_List_Price__c = mssTwoPrices[i],
                GSS_Product__c = mssTwo.Id
            ));
            prodPricingList.add(new  SC_DD_Product_Pricing__c(
                recordtypeId = prodPricingRecTypeId,
                Currency__c = currencyTypes[i],
                Local_List_Price__c = rssTwoPrices[i],
                GSS_Product__c = rrsTwo.Id
            ));
            prodPricingList.add(new  SC_DD_Product_Pricing__c(
                recordtypeId = prodPricingRecTypeId,
                Currency__c = currencyTypes[i],
                Local_List_Price__c = soaTwoPrices[i],
                GSS_Product__c = soaTwo.Id
            ));
        }  
        
        insert prodPricingList;
        
    }
}