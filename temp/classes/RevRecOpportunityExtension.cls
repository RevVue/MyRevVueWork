global with sharing class RevRecOpportunityExtension {

    public Opportunity opp {get;set;} 
    public Opportunity oppty {get;set;}
    RevRecAppSetting__c theSetting;

    //Code added - 02/18/2015 - As per Advance currency management issue
    public String oppTotalOpportunity{get;set;}
    public String oppTotalRecognized{get;set;} 
    public String oppTotalDeferred{get;set;}
    public String oppTotalResidual{get;set;}  
    public Boolean isMultiCurrencyEnabled {get;set;} 
    
    //Code added - 11/15/2017 - As per Weighted calculation
    public String oppTotalOpportunityWeighted{get;set;}
    public String oppTotalRecognizedWeighted{get;set;} 
    public String oppTotalDeferredWeighted{get;set;}
    public String oppTotalResidualWeighted{get;set;}
    
    //Code added - 04/19/2016 - As per to enable revrecrule on Line item level 
    public String oppLineItemRow {get;set;}  
    public List<OpportunityLineItemWrapper> OppLineItems;
    public List<OpportunityLineItemWrapper> lineItemsWrap {get;set;}
    public Boolean isPopupshow {get;set;}
    public String oppRuleId {get;set;}
    public String oppRuleName {get;set;}
    public String currencyFormate {get;set;}
    public String oppRuleValue {get; set;}
    
    //Inlilize utility class
    Utility utl;         
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldOppResult = Utility.getFieldPermissions('Opportunity');
    Static Map<String, Schema.DescribeFieldResult> mapfieldOppLIResult = Utility.getFieldPermissions('OpportunityLineItem');
    Static Map<String, Schema.DescribeFieldResult> mapfieldRevRecOppLIResult = Utility.getFieldPermissions('RevRecOpportunityLineItem__c');
    
    //String to hold user's currency
    String userCurrencyIsoCode = userInfo.getDefaultCurrency();
              
    List<String> args = new String[]{'0','number','$###,###,##0.00'};
        
    public RevRecOpportunityExtension (ApexPages.StandardController stdController) {  
        
        //Initilization
        currencyFormate = userInfo.getDefaultCurrency();
        oppLineItemRow = '';
        oppRuleId = '';
        oppRuleValue = '';
        isPopupshow = false;
        lineItemsWrap = new List<OpportunityLineItemWrapper>();
        
        //boolean to get if multi currency enabled 
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        //Getting opportuniy record
        opp = (Opportunity )stdController.getRecord();
        
        //Code added - 04/21/2016
        //Added RevRecRule__c in query 
        if(opp.Id != null) 	
            oppty = [Select ID, StageName, IsWon, IsClosed , CloseDate, REVvue_RevRecRule__c, REVvue_RevRecRule__r.Name, REVvue_RuleAssignment__c, Probability,
                     REVvue_RuleAssignment__r.Name, LastActivityDate From Opportunity where Id  =: opp.Id];
        
        //Inlilize utility class
        utl = new Utility(oppty);
        
        //Query through app setting
        List<RevRecAppSetting__c> theSettingList = [select Id, Is_Closed_Date_Validation__c, Name, Opportunity_Stage__c, Time_of_Month_Selection_Types__c, Time_of_Month_Selection_Types_tr__c, Certain_weekday_tr__c,Certain_weekday_day__c, Certain_days_before_last_weekday__c, Certain_days_before_last_weekday_tr__c,
                                                    Opportunity_Type__c,  Selected_Start_Date_Types__c, Selected_End_Date_Types__c, Certain_date_of_month__c, Certain_date_of_month_tr__c, Certain_weekday__c, Certain_weekday_day_tr__c, Certain_days_before_last_weekday_day__c, Certain_days_before_last_weekday_day_tr__c, DiagnosticsEnabled__c 
                                                    FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
        
        //checing list size
        if (theSettingList.Size() == 0 ) {
            theSetting = new RevRecAppSetting__c(Name='AppSetting', 
                                                Time_of_Month_Selection_Types__c = '1' ,
                                                Time_of_Month_Selection_Types_tr__c = '1'   
                                                );
        } else 
            theSetting = theSettingList[0];
    }
    
    //Method tto get oportunity line item
    public List<OpportunityLineItemWrapper> getOppLineItems() {
        
        //Wrapper list to be returned
        list<OpportunityLineItemWrapper> resultList = new list<OpportunityLineItemWrapper>();
        
        //Checking if list is null / first time call of getter
        OppLineItems =  new list<OpportunityLineItemWrapper>();
        
        //String to hold opportunity id  
        String oppId = opp.id;           
        
        //Set defaults
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalOpportunity__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalOpportunity__c = 0; 
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalRecognized__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalRecognized__c = 0;
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalResidual__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalResidual__c = 0;
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalDeferred__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalDeferred__c = 0;
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_Total_Opp_wei__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_Total_Opp_wei__c = 0; 
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalRecognizedwei__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalRecognizedwei__c = 0;
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalResidualwei__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalResidualwei__c = 0;
        if(Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalDeferredwei__c',Constants.PERMISSION_UPDATE))
            opp.REVvue_TotalDeferredwei__c = 0;
        
        //Queery through opportunity line items  
        //Code added - 04/19/2016 - As per to enable revrecrule on Line item level 
        //Added RevRecRule__c in query  
        //Code added - 07/14/2016 - FEATURE # 8: Add links the assignment rule on oppty
        //Added Rule_Assignment__c, Rule_Assignment__r.Name, Rule_Assignment_Type__c in query 
        List<OpportunityLineItem> oli = 
            [SELECT Id,Name , PricebookEntryId, Quantity, Description, UnitPrice,TotalPrice, RevRecRule__c,
             Overriden_Rule_Assignment_Id__c, RevRecRule__r.Start_Percentage__c, Rule_Assignment__c, 
             Rule_Assignment__r.Name, Rule_Assignment_Type__c,RevRecRule__r.Name,
             PricebookEntry.Name,RevRecRule__r.End_Percentage__c,
             PricebookEntry.product2.RevRecRule__r.Id, 
             PricebookEntry.product2.Id,
             PricebookEntry.product2.Name,
             PricebookEntry.product2.RevRecRule__r.name,      
             PricebookEntry.product2.RevRecRule__r.Active__c, 
             PricebookEntry.product2.RevRecRule__r.Milestone_Type__c,
             RevRecOpportunityLineItem__r.Id, RevRecOpportunityLineItem__c,   
             RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
             RevRecOpportunityLineItem__r.TotalRev__c,
             RevRecOpportunityLineItem__r.DeferredRev__c,
             RevRecOpportunityLineItem__r.RecognizedRev__c,
             RevRecOpportunityLineItem__r.RecRevWei__c,
             RevRecOpportunityLineItem__r.DefReWei__c,
             RevRecOpportunityLineItem__r.CalculatedAt__c,
             RevRecOpportunityLineItem__r.ResidualAmount__c,
             RevRecOpportunityLineItem__r.ResAmtWei__c,
             RevRecOpportunityLineItem__r.ProductName__c,
             RevRecOpportunityLineItem__r.Allocated__c,
             RevRecOpportunityLineItem__r.Converted_Recognized_Amount__c
             FROM OpportunityLineItem WHERE OpportunityId =: opp.Id FOR UPDATE];
        
        Set<id> lineItemIds = new Set<id>();
        //Lopp through line items
        if(oli.size() > 0) {
            
            for(OpportunityLineItem item: oli) {
                
                if (item.Quantity != null && item.UnitPrice != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalOpportunity__c',Constants.PERMISSION_UPDATE)))
                    opp.REVvue_TotalOpportunity__c += item.TotalPrice; 
                if (item.Quantity != null && item.UnitPrice != null && oppty.Probability != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_Total_Opp_wei__c',Constants.PERMISSION_UPDATE)))
                    opp.REVvue_Total_Opp_wei__c += (item.TotalPrice * oppty.Probability)/100;                
                if (item.RevRecOpportunityLineItem__r != null)  {           
                    if (item.RevRecOpportunityLineItem__r.RecognizedRev__c != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalRecognized__c',Constants.PERMISSION_UPDATE)))
                        opp.REVvue_TotalRecognized__c += item.RevRecOpportunityLineItem__r.RecognizedRev__c;
                    if (item.RevRecOpportunityLineItem__r.DeferredRev__c != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalDeferred__c',Constants.PERMISSION_UPDATE)))
                        opp.REVvue_TotalDeferred__c += item.RevRecOpportunityLineItem__r.DeferredRev__c; 
                    if (item.RevRecOpportunityLineItem__r.ResidualAmount__c != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalResidual__c',Constants.PERMISSION_UPDATE)))
                        opp.REVvue_TotalResidual__c += item.RevRecOpportunityLineItem__r.ResidualAmount__c;
                    if (item.RevRecOpportunityLineItem__r.RecRevWei__c != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalRecognizedwei__c',Constants.PERMISSION_UPDATE)))
                        opp.REVvue_TotalRecognizedwei__c += item.RevRecOpportunityLineItem__r.RecRevWei__c;
                    if (item.RevRecOpportunityLineItem__r.DefReWei__c != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalDeferredwei__c',Constants.PERMISSION_UPDATE)))
                        opp.REVvue_TotalDeferredwei__c += item.RevRecOpportunityLineItem__r.DefReWei__c;             
                    if (item.RevRecOpportunityLineItem__r.ResAmtWei__c != null && (Utility.checkFieldPermission(mapfieldOppResult,'REVvue_TotalResidualwei__c',Constants.PERMISSION_UPDATE)))
                        opp.REVvue_TotalResidualwei__c += item.RevRecOpportunityLineItem__r.ResAmtWei__c; 
                }  
                
                if (item.RevRecOpportunityLineItem__r != null)
                    lineItemIds.add(item.RevRecOpportunityLineItem__r.id) ;         
            }
        }   
        
        //Code added - 02/18/22015 -  As per Advance currency management issue 
        //Checking if multi currency enabled org
        if(isMultiCurrencyEnabled) {
            
            //Calling utility method to get the Amount formatted
            oppTotalOpportunity = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalOpportunity__c);
            oppTotalRecognized = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalRecognized__c);
            oppTotalDeferred = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalDeferred__c);
            oppTotalResidual = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalResidual__c);
            
            //Calling utility method to get the Amount formatted for Weighted
            oppTotalOpportunityWeighted = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_Total_Opp_wei__c);
            oppTotalRecognizedWeighted = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalRecognizedwei__c );
            oppTotalDeferredWeighted = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalDeferredwei__c);
            oppTotalResidualWeighted = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), opp.REVvue_TotalResidualwei__c);
        }
                   
        if (oli.size() != 0) {
            
            List<RevRecProductRule__c> overrideRuleList;
            
            if(lineItemIds.size() > 0)
                overrideRuleList = [select id, name, RevRecOpportunityLineItem__c, Enable_Manual_Forecast__c, Is_Manual_Update__c, 
                                    Is_Default_Overriden__c, Forecast_With_Zero_Value__c
                                    from RevRecProductRule__c where RevRecOpportunityLineItem__c in :lineItemIds];
            Map<id, RevRecProductRule__c> overrideRuleMap = new Map<id, RevRecProductRule__c>();
            
            for(RevRecProductRule__c item : overrideRuleList)  
                overrideRuleMap.put(item.RevRecOpportunityLineItem__c, item);  
            
            Map<string, List<OpportunityLineItemWrapper>> listMap = new Map<string, List<OpportunityLineItemWrapper>>();
            
            for(OpportunityLineItem item: oli) {
            
                OpportunityLineItemWrapper wrapperItem = new OpportunityLineItemWrapper();
                wrapperItem.LineItem = item;
                
                //Code added - 02/20/2015 - As per Advance Currency Management Issue
                //Checking if multi currency enabled 
                if(isMultiCurrencyEnabled) {
                    
                    //Checking for null
                    if(item.UnitPrice != null)
                        wrapperItem.lineItemSalesPrice = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), item.UnitPrice);
                    else
                        wrapperItem.lineItemSalesPrice = opp.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                    
                    //Checking for null
                    if(item.TotalPrice != null)
                        wrapperItem.lineItemTotalPrice = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), item.TotalPrice);
                    else
                        wrapperItem.lineItemTotalPrice = opp.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                }
                
                string ruleDisplay = '';
                string ruleId = '';
                boolean hasOverriddenRule = false;
                
                if (item.RevRecOpportunityLineItem__r != null) {
                    RevRecProductRule__c overrideRule;
                    
                    if(overrideRuleMap.containsKey(item.RevRecOpportunityLineItem__r.id))
                        overrideRule = overrideRuleMap.get(item.RevRecOpportunityLineItem__r.id);
                    
                    if (overrideRule != null) {
                        ruleDisplay = overrideRule.name;
                        if(!overrideRule.Is_Default_Overriden__c)
                            hasOverriddenRule = true;
                    } 
                }
                
                if (ruleDisplay == '') {
                    if (item.PricebookEntry.product2.RevRecRule__r != null) 
                        ruleDisplay = item.PricebookEntry.product2.RevRecRule__r.name;
                    else 
                        ruleDisplay = 'No Rule';
                }
                
                if (ruleDisplay.length() > 25) 
                    ruleDisplay = ruleDisplay.substring(0, 22) + '...';
                if (ruleDisplay == 'No Rule')                       
                    wrapperItem.RuleNameDisplay = ruleDisplay ;
                else 
                    wrapperItem.RuleNameDisplay = '"' + ruleDisplay + '"';
                
                wrapperItem.HasOverriddenRule = hasOverriddenRule;
                wrapperItem.RevRecLineItem = item.RevRecOpportunityLineItem__r;
                
                //Code added - 02/20/2015 - As per Advance Currency Management Issue
                //Checking if multi currency enabled 
                if(isMultiCurrencyEnabled) {
                     
                    //Checking for null                        
                    if(item.RevRecOpportunityLineItem__r.DeferredRev__c != null)
                        wrapperItem.revRecDeferredPrice = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), item.RevRecOpportunityLineItem__r.DeferredRev__c);
                    else
                        wrapperItem.revRecDeferredPrice = opp.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                    
                    //Checking for null
                    if(item.RevRecOpportunityLineItem__r.RecognizedRev__c != null)
                        wrapperItem.revRecRecognizedRev = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), item.RevRecOpportunityLineItem__r.RecognizedRev__c);
                    else
                        wrapperItem.revRecRecognizedRev = opp.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                        
                    //Checking for null                        
                    if(item.RevRecOpportunityLineItem__r.DefReWei__c != null)
                        wrapperItem.revRecDeferredPriceWeighted = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), item.RevRecOpportunityLineItem__r.DefReWei__c);
                    else
                        wrapperItem.revRecDeferredPriceWeighted = opp.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                    
                    //Checking for null
                    if(item.RevRecOpportunityLineItem__r.RecRevWei__c != null)
                        wrapperItem.revRecRecognizedRevWeighted = utl.calculateAmountInCurrency(String.valueOf(opp.get('CurrencyIsoCode')), item.RevRecOpportunityLineItem__r.RecRevWei__c);
                    else
                        wrapperItem.revRecRecognizedRevWeighted = opp.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                }
                
                if (listMap.containsKey(item.PricebookEntry.Name))
                    listMap.get(item.PricebookEntry.Name).add(wrapperItem);
                else
                    listMap.put(item.PricebookEntry.Name, new OpportunityLineItemWrapper[] {wrapperItem});
            }
            
            List<String> nameList = new List<string>();
            nameList.AddAll(listMap.keySet());
            nameList.sort();
            for(string s: nameList){
                OppLineItems.addAll(listMap.get(s));
            }
        }
           
        return OppLineItems;  
    }
    
    public String getOpportunityId() {
        return opp.id;
    } 

    public PageReference ReCalculateAll(){ 

        String oppId = opp.id; 
        RevRecUtil util = new RevRecUtil();
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
        utilHelper.Cleanup();
        String msg = '';
        
        msg = util.EvaluateRevRecScheduleForOpportunity(oppId);
        
        if(String.isNotBlank(msg) && msg != '' && msg != 'null') {
            if(msg.length() > 0)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg));
        }
        return null;
    }
    
    private Id queryItemId;
    public string getQueryItemId() {return queryItemId; }
    public void setQueryItemId(string value) {queryItemId = value;}
    
    private Id queryProduct2Id;
    public String getQueryProduct2Id() {return queryProduct2Id;}
    public void setQueryProduct2Id(String value) {queryProduct2Id = value;}
    
    public string formatCurrencyFromDecimal(Decimal input){
        Decimal dollars;
        Decimal cents;
        dollars = input.intValue();
        cents = input-dollars;
        cents = cents.setScale(2);  
        String amtText = '$' + dollars.format() + cents.toPlainString().substring(1);
        return amtText;
    }
    
    public PageReference resetOverriddenRule() {
        
        String opportunityId = opp.id; 
        Id lineItemId = queryItemId;
        Id product2Id = queryProduct2Id;
        
        if (!Schema.SObjectType.Opportunity.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access: Opportunity'));
            return null;                                                
        }

        if (!Schema.SObjectType.OpportunityStage.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access: OpportunityStage'));
            return null;                                                
        }

        if (!Schema.SObjectType.OpportunityLineItem.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access: OpportunityLineItem'));
            return null;                                                
        }
        RevRecUtil theUtil = new RevRecUtil();
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
        utilHelper.Cleanup();       

        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opportunityId);
        OpportunityStage theStage = null;
        List<OpportunityStage>  stageList = [SELECT Id, Description, MasterLabel FROM  OpportunityStage WHERE MasterLabel = :theOppty.StageName];
        if (stageList.size() > 0)
             theStage = stageList[0];

        Id contractId = theOppty.ContractId;
        
        OpportunityLineItem oli = RevRecHelper.GetLineItemWithAllFeilds(lineItemId); 
        Product2 product2 = RevRecHelper.GetProduct2WithAllFeilds(product2Id);
        Contract contr = RevRecHelper.GetContractWithAllFeilds(contractId);
        
        //Code added - 04/19/2016 - As per to enable revrecrule on Line item level 
        //Added RevRecRule__c in query      
        OpportunityLineItem lineItem =  
                [SELECT Id, Name  ,TotalPrice, PricebookEntry.Name, PricebookEntry.product2.id, RevRecRule__c, Rule_Assignment__c,
                    RevRecRule__r.Name,
                    RevRecRule__r.Active__c, 
                    RevRecRule__r.Default_Rule__c, 
                    RevRecRule__r.Description__c, 
                    RevRecRule__r.Divide_By__c, 
                    RevRecRule__r.initial_amount__c, 
                    RevRecRule__r.initial_amount_type__c, 
                    RevRecRule__r.Offset_Period__c,  
                    RevRecRule__r.offset_type__c,
                    RevRecRule__r.Period__c, 
                    RevRecRule__r.Period_or_Exact_Days__c, 
                    RevRecRule__r.Recognition_Type__c, 
                    RevRecRule__r.Residual_Amount__c, 
                    RevRecRule__r.Residual_Amount_Type__c, 
                    RevRecRule__r.Revenue_Recognition_End_Date__c,  
                    RevRecRule__r.Revenue_Recognition_Start_Date__c,
                    RevRecRule__r.Milestone_Type__c,
                    RevRecRule__r.Start_Percentage__c,
                    RevRecRule__r.End_Percentage__c,
                    RevRecRule__r.Is_Split_Categories__c,
                    RevRecRule__r.Enable_Manual_Forecast__c,
                    RevRecRule__r.Forecast_With_Zero_Value__c,
                    RevRecOpportunityLineItem__r.Id,
                    RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
                    RevRecOpportunityLineItem__r.TotalRev__c,
                    RevRecOpportunityLineItem__r.DeferredRev__c,
                    RevRecOpportunityLineItem__r.RecognizedRev__c,
                    RevRecOpportunityLineItem__r.CalculatedAt__c,
                    RevRecOpportunityLineItem__r.ResidualAmount__c,
                    RevRecOpportunityLineItem__r.DefReWei__c,
                    RevRecOpportunityLineItem__r.RecRevWei__c,
                    RevRecOpportunityLineItem__r.ResAmtWei__c,
                    RevRecOpportunityLineItem__r.ProductName__c, 
                    RevRecOpportunityLineItem__r.Opportunity__c,
                    RevRecOpportunityLineItem__r.Opportunity__r.REVvue_RevRecRule__c,
                    RevRecOpportunityLineItem__r.Converted_Recognized_Amount__c,
                    PricebookEntry.product2.RevRecRule__r.Id, 
                    PricebookEntry.product2.RevRecRule__r.name, 
                    PricebookEntry.product2.RevRecRule__r.Active__c, 
                    PricebookEntry.product2.RevRecRule__r.Default_Rule__c, 
                    PricebookEntry.product2.RevRecRule__r.Description__c, 
                    PricebookEntry.product2.RevRecRule__r.Divide_By__c, 
                    PricebookEntry.product2.RevRecRule__r.initial_amount__c, 
                    PricebookEntry.product2.RevRecRule__r.initial_amount_type__c, 
                    PricebookEntry.product2.RevRecRule__r.Offset_Period__c,  
                    PricebookEntry.product2.RevRecRule__r.offset_type__c,
                    PricebookEntry.product2.RevRecRule__r.Period__c, 
                    PricebookEntry.product2.RevRecRule__r.Period_or_Exact_Days__c, 
                    PricebookEntry.product2.RevRecRule__r.Recognition_Type__c, 
                    PricebookEntry.product2.RevRecRule__r.Residual_Amount__c, 
                    PricebookEntry.product2.RevRecRule__r.Residual_Amount_Type__c, 
                    PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_End_Date__c,  
                    PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_Start_Date__c,
                    PricebookEntry.product2.RevRecRule__r.Milestone_Type__c
                    //Code added - 11/06/2014 - As per Amortized Milestone Rule Requirements
                    //Add feild in query
                FROM OpportunityLineItem WHERE Id = :lineItemId];
                
        // RevRecRules__c rule = lineItem.PricebookEntry.Product2.RevRecRule__r;
        RevRecRules__c rule = lineItem.RevRecRule__r;
        List<RevRecRuleMilestone__c> revRecRulesMilestones = new List<RevRecRuleMilestone__c>();
        
        //Code added - 06/15/2015 -  As  per Blended Revernue recognition
        List<RevRecRuleCategory__c> revRecRuleCategories = new List<RevRecRuleCategory__c>();
        
        //Code added - 01/19/2015 - As per  Milestone Date Automation Requirements
        //Add feild in query Milestone_Date_Source__c
        if (rule != null) { 
            revRecRulesMilestones = [select Id, name, Milestone_Sequence__c, Milestone_Name__c, Actual_Percent__c, Percent__c, Milestone_Date_Source__c, Projected_Qty__c, Projected_Amount__c,
                                      Projected_Percent__c, Milestone_Date_Source_Label__c, Amount__c, Qty__c, Milestone_Date__c FROM RevRecRuleMilestone__c 
                                     where RevRecRule__c = :rule.Id ORDER BY Milestone_Sequence__c];
            
            //Code added - 06/15/2015 -  As  per Blended Revernue recognition
            revRecRuleCategories = [SELECT Id,  Name, RevRecRule__c, Sequence__c, Percent__c, Amount__c, Category_Type__c, Projected_Qty__c, Projected_Amount__c, 
                                    Category_End_Date__c , Category_Start_Date__c, Line_Item__c, Qty__c ,Level__c, Projected_Percent__c
                                    From RevRecRuleCategory__c Where RevRecRule__c = :rule.Id ORDER BY Sequence__c];
        }
        
        RevRecOpportunityLineItem__c revRecLineItem = null;
        
        if (lineItem.RevRecOpportunityLineItem__r != null) {
            revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
            if (revRecLineItem != null) {
                if (!Schema.SObjectType.RevRecProductRule__c.isDeletable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access: RevRecProductRule'));
                    return null;                                                
                }
                
                List<RevRecProductRule__c> overrideRuleList = [select Id, name, Enable_Manual_Forecast__c, Forecast_With_Zero_Value__c
                    from RevRecProductRule__c where RevRecOpportunityLineItem__c = :revRecLineItem.Id];
                
                if (RevRecProductRule__c.sObjectType.getDescribe().isDeletable()) {
                    delete (overrideRuleList);   
                }
            }
            
            if (!Schema.SObjectType.RevRecOpportunityLineItemSchedule__c.isDeletable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access: RevRecOpportunityLineItemSchedule'));
                    return null;                                                
            }
            List<RevRecOpportunityLineItemSchedule__c> garbage = [select id, name from RevRecOpportunityLineItemSchedule__c where OpportunityLineItemId__c  = :lineItemId]; 
            if (RevRecOpportunityLineItemSchedule__c.sObjectType.getDescribe().isDeletable()) {
                delete (garbage);
            }
        } 
        
        if (revRecLineItem == null) {
            revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name,  opportunity__c = opportunityId, OpportunityLineItemId__c = lineItemId);
            if (!Schema.SObjectType.RevRecOpportunityLineItem__c.isCreateable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access: RevRecOpportunityLineItem'));
                    return null;                                                
            }
            insert(revRecLineItem);
            oli.RevRecOpportunityLineItem__c = revRecLineItem.id;
            if(Utility.checkFieldPermission(mapfieldRevRecOppLIResult,'ProductName__c',Constants.PERMISSION_UPSERT))
                revRecLineItem.ProductName__c = lineItem.PricebookEntry.Name;
        }
        
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
        //Code added - 06/15/2015 - As per Blended revenue recognition requirement
        List<RevRecProductRuleCategory__c> revRecProductRuleCategories = new  List<RevRecProductRuleCategory__c>();
        RevRecProductRule__c overrideRule = new RevRecProductRule__c();
        //Code added - 11/05/2014 -As per Amortized Milestone Rule Requirements
        Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();

        String msg = theUtil.CalculateOverrideRuleFromRevRecRule(theOppty, oli, product2, rule, overrideRule, revRecRulesMilestones, revRecProductRuleMilestones,mapRevRecMileStoneWithName, revRecRuleCategories ,revRecProductRuleCategories, utl, contr);
        
        if (msg != '' && msg != null && msg!= 'null')   {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                return null;
        }   

        List<RevRecOpportunityLineItemSchedule__c> newSchedules = new  List<RevRecOpportunityLineItemSchedule__c>();
            
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        oliList.add(oli);

        List<RevRecOpportunityLineItem__c> revRecOliList = new List<RevRecOpportunityLineItem__c>();
        if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecOpportunityLineItem__c'))
            revRecOliList.add(revRecLineItem);
            
        List<RevRecProductRule__c> overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
            
        //Code added - 06/18/2015 -  As per Amortize milestone Revenue Recognition 
        Map<id, List<RevRecProductRuleMilestone__c>> revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(oli.id, revRecProductRuleMilestones);
            
        //Code added - 06/18/2015 -  As per Blended Revenue Recognition 
        Map<Id, List<RevRecProductRuleCategory__c>> mapLineItemWithProductCategory = new  Map<Id, List<RevRecProductRuleCategory__c>>();
        mapLineItemWithProductCategory.put(oli.Id, revRecProductRuleCategories);

        //Map to hold list of milestones with rule
        Map<Id, List<RevRecRuleMilestone__c>> mapRuleIdWithListOfMiles = new Map<Id, List<RevRecRuleMilestone__c>>();
        msg += theUtil.EvaluateRevRecSchedule(theOppty, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);

        oli.Overriden_Rule_Assignment_Id__c = '';
        oli.Overridden_Rule__c = '';
        
        update(oliList);
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecOpportunityLineItem__c')){
            update(revRecOliList);
        }
        insert(newSchedules);
          
        overrideRule.Total_Period__c = null;
        if (msg != '' && msg != null && msg != 'null') 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
        
        //Code added- As per to enable Rule assignment on line item level
        //04/20/2016 
        //Checking for blank value
        if(String.isNotBlank(oppLineItemRow)) {
            
            OppLineItems[Integer.valueOf(oppLineItemRow)].HasOverriddenRule = false;
            OppLineItems[Integer.valueOf(oppLineItemRow)].LineItem.RevRecRule__c = lineItem.PricebookEntry.Product2.RevRecRule__c;
            
            //Calling method to recalculate all rules again
            ReCalculateAll();
        }
        return null;
    } 
    
    /**
     *  @description    :   This method is used to upsert the Line item , while new rule is selected from the lookup dialog box in opportunity inline page.
     *
     *  @args           :   
     *
     *  @return         :   
    **/  
    public void saveRuleOnOppLineItems() { 
        //List of line item to be updated 
        List<OpportunityLineItem> oppLinesToBeUpdated = new List<OpportunityLineItem>();

        //Code modified on 08/27/2018 - to check if lookup field is not blank out, then only update rule on line item
        //Check if value is not blank or null
        if((oppRuleValue != '' && oppRuleValue != null) || Utility.getUITheme() == 'Theme4d') {        
            
            //Checking for the row count
            if(String.isNotBlank(oppLineItemRow) && String.isNotBlank(oppRuleId)) {
                
                OpportunityLineItem op = OppLineItems[Integer.valueOf(oppLineItemRow)].LineItem;
                if(Utility.checkFieldPermission(mapfieldOppLIResult,'RevRecRule__c',Constants.PERMISSION_UPSERT))
                    op.RevRecRule__c = oppRuleId.trim();
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'OpportunityLineItem'))
                    oppLinesToBeUpdated.add(op);        
            }
          
            //Update line item
            if(oppLinesToBeUpdated.size() > 0) {
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'OpportunityLineItem')){
                    update oppLinesToBeUpdated;
                }
                    
                //List of Rule
                List<RevRecRules__c> revRecRule = [Select Id , Recognition_Type__c, Is_Split_Categories__c From RevRecRules__c where ID =:  oppLinesToBeUpdated[0].RevRecRule__c LIMIT 1];
                
                //Set wrapper proprties
                OppLineItems[Integer.valueOf(oppLineItemRow)].HasOverriddenRule = true;
                
                //Putting page param  
                ApexPages.CurrentPage().getParameters().put('opportunityLineItemId' , oppLinesToBeUpdated[0].Id);
                ApexPages.CurrentPage().getParameters().put('opportunityId' , opp.Id);
                
                //Query to fetch already existing overriden rule 
                List<RevRecProductRule__c> existingRules = [Select Id From RevRecProductRule__c Where RevRecOpportunityLineItem__c =: oppLinesToBeUpdated[0].RevRecOpportunityLineItem__c];
                        
                //Checking for the list size and delete that rule after that creating a new one.
                if(existingRules.size() > 0 && (RevRecProductRule__c.sObjectType.getDescribe().isDeletable())) 
                    delete existingRules;
                
                //Calling methods 
                RevRecProductRuleController controller = new RevRecProductRuleController();
                
                //Cehcking for Split categories on Rule Defination level
                if(revRecRule.size() > 0 && revRecRule[0].Is_Split_Categories__c){
                }else{
                     controller.save();
                }
                //Calling method to recalculate all rules again
                ReCalculateAll();
            }
        }
    }
    
    /** FEATURE #6 **/
    /**
     *  @description    :   This method is used to open line item popup window whenever rule selected in the rule lookup field on opportunity level.
     *
     *  @args           :   -
     *
     *  @return         :   void
    **/
    public void showLineItemPopUpScreen () {
        
        //Initilization
        lineItemsWrap =  new List<OpportunityLineItemWrapper>();
        
        //Loop over LineItems and populate new list 
        for(OpportunityLineItemWrapper liWrap : OppLineItems) {
            
            liWrap.isSelectedLineItem = false;
            lineItemsWrap.add(liWrap);
        }
        
        //Check for lightning theme
        if(String.isNotBlank(oppRuleId) && Utility.getUITheme() == 'Theme4d'/*isInLightning*/) 
            oppty.REVvue_RevRecRule__c = oppRuleId.trim();
        
        isPopupshow = true;
    }
    
    /**
     *  @description    :   This method is used to open line item popup window whenever rule selected in the rule lookup field on opportunity level.
     *
     *  @args           :   -
     *
     *  @return         :   void
    **/
    public void saveOpportunityLevelRule() {
        
        //Set to hold revrecopportunitylineitem Id's
        Set<Id> revRecIds = new Set<Id>();
        
        //Map of OLI Id's And OLI
        Map<Id, OpportunityLineItem> mapRuleIdWithOLIToBeUpdate = new Map<Id, OpportunityLineItem>();
        
        String msg = '';
        
        //Loop over wrapper list
        for(OpportunityLineItemWrapper liWrap : lineItemsWrap) {
            
            //Checking for selected value
            if(liWrap.isSelectedLineItem) {
                 
                liWrap.LineItem.RevRecRule__c = oppty.REVvue_RevRecRule__c;
                mapRuleIdWithOLIToBeUpdate.put(liWrap.LineItem.RevRecOpportunityLineItem__c, liWrap.LineItem);
                            
                revRecIds.add(liWrap.LineItem.RevRecOpportunityLineItem__c);
            }
        }
        
        //Check if, opportunity have rule and revrecopportunitylineitem
        if(oppty.REVvue_RevRecRule__c != null && revRecIds.size() > 0) {
            
            //Class instance
            OverriddenRuleInsertionOnOpptyLevel ctrl = new OverriddenRuleInsertionOnOpptyLevel();
            
            //Method call to create overridden rule
            msg = ctrl.overriddenRuleOnOpptyLevel(oppty, mapRuleIdWithOLIToBeUpdate, revRecIds);
        }
        
        if(msg.length() == 0) {
            
            //Checking for the list size
            if(mapRuleIdWithOLIToBeUpdate.size() > 0) 
                update mapRuleIdWithOLIToBeUpdate.values();  
            
            //Code is updated by bill on 06/20/2016
            //check if oppty is null
            if(oppty != null) {
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'Opportunity')){
                    update oppty; //updating opportunity with new rule
                }
                
                //Added RevRecRule__c in query 
                oppty = [Select ID, StageName, IsWon, IsClosed , CloseDate, REVvue_RevRecRule__c, REVvue_RevRecRule__r.Name, REVvue_RuleAssignment__c, Probability,
                 REVvue_RuleAssignment__r.Name, LastActivityDate From Opportunity where Id  =: opp.Id];
            }
        }
        //Calling method to recalculate all rules again
        ReCalculateAll();
    }
    
    public PageReference ReCalculateTheLineItem() {
        return null;
    }
    
    //Used to fetch Contact for mobile user lookup using auto complete
    @RemoteAction
    global static List<RevRecRules__c> queryRules(String keyword) {
        List<RevRecRules__c> rules = new List<RevRecRules__c>();
        if (keyword != null && keyword.trim() != '') {
            keyword =   '%'+ keyword + '%';
            rules = [Select Id, Name, Recognition_Type__c from RevRecRules__c where Name like :keyword ORDER BY Name];
        } else
            rules = [Select Id, Name, Recognition_Type__c from RevRecRules__c where Active__c = true ORDER BY Name];
        
        return rules;
    }
 }