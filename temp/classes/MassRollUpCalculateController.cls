/**
*  Description     :   Class to calculate Rollup calculation on opportunity level.
*
*  Created By      :   Bill Feeheley
*
*  Version         :   V_1.0
*
**/
public with sharing class MassRollUpCalculateController {
    //Properties
    public Opportunity oppty{ get; set; }
    public Boolean isMultiCurrencyEnabled { get; set; }
    public String oppTotalOpportunity { get; set; }
    public String oppTotalOpportunityWei { get; set; }
    public Decimal oppTotalOpportunityForSingleCurrency { get; set; }
    public Decimal oppTotalOpportunityWeiForSingleCurrency { get; set; }
    public Date CloseDateValue { get; set; }
    public String currencyFormate { get; set; }
    public Utility utl;
    
    public Id opportunityId;
    private Set<Id> opportunityLineItemIds;
    private Double recognized;
    public Boolean isHavingPermssion { get; set; }
    public Boolean IsHavingFiscalYear{ get; set; }
    public String selectedYear { get; set; }
    public List<String> theListOfYears{ get; set; } 
    
    //Initilze wrapper class
    public List<CurrentFiscalYearMonthlyRecords> currentMonthlyFiscalYear { get; set; }
    public List<yearlyWrapper> listOfYearlyWrapper { get; set; }
    public List<monthlyWrapper> listOfMonthlyWrapper { get; set; }
    public List<fiscalYearMonthlyRecordsWithSingleCurrency> fiscalYearWithSingleCurrency { get; set; }
    public List<Yearly_Revenue_Rollups__c> listOfYearlyRollupToInsert { get; set; }
    public List<Monthly_Revenue_Rollups__c> monthlySelectedRevenueRollups { get; set; }
    public List<Yearly_Revenue_Rollups__c> yearlyRollupsFY { get; set; }
    public Map<String, List<Monthly_Revenue_Rollups__c>> mapOfYearlyIdWithMonthlyRollups{ get; set; }
    public List<Monthly_Revenue_Rollups__c> listUpdateOfMonthly;
    public List<RevRecOpportunityLineItemSchedule__c> rrOpportunityLineItemSchedules;
    
    //String to hold user's currency
    String userCurrencyIsoCode = userInfo.getDefaultCurrency();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldYearlyResult = Utility.getFieldPermissions('Yearly_Revenue_Rollups__c');
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldMonthlyResult = Utility.getFieldPermissions('Monthly_Revenue_Rollups__c');
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldOppResult = Utility.getFieldPermissions('Opportunity');
    
    
    /**
    *  @Description    :    constructor
    **/
    public void MassRollUpCalculateController() {
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        
        List<PermissionSetAssignment> lstcurrentUserPerSet = [SELECT Id, PermissionSet.Name,AssigneeId
                                                              FROM PermissionSetAssignment
                                                              WHERE AssigneeId = :Userinfo.getUserId()
                                                              AND PermissionSet.Name IN('REVvue_Opportunity_Mass_Rollup_Calculation') ];
        if(lstcurrentUserPerSet.size() > 0) {
            for (PermissionSetAssignment psa: lstcurrentUserPerSet) {
                if(psa.PermissionSet.Name.equals('REVvue_Opportunity_Mass_Rollup_Calculation')) 
                    isHavingPermssion = true;
                else
                    isHavingPermssion = false;
            }
        }
        else
            isHavingPermssion = false;
        
        if(isHavingPermssion == true) {
            opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
            String queryOpp = '';
            
            //Check if, multicurrency is enable
            if(!isMultiCurrencyEnabled)
                queryOpp += 'SELECT Id, name, CloseDate , TCV_Actual__c, Probability FROM Opportunity WHERE Id = \''+ String.escapeSingleQuotes(opportunityId) +'\' WITH SECURITY_ENFORCED LIMIT 1 ';
            else
                queryOpp += 'SELECT Id, name, CurrencyIsoCode, CloseDate , TCV_Actual__c, Probability FROM Opportunity WHERE Id = \''+ String.escapeSingleQuotes(opportunityId) +'\' WITH SECURITY_ENFORCED LIMIT 1 ';
            
            //Database.query for schedules
            List<Opportunity> listOfallOpp = database.query(queryOpp);
            
            //Inlilize class
            oppty = listOfallOpp[0];
            
            MassRollupRevenueCalculation(listOfallOpp);
        }
        else 
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You are not authorized to view this page'));
    }
    /**
    *  @Description    :    This method is used to do rollup calculations for monthly and yearly revenue
    *
    *  @args           :	List<Opportunity>    
    *
    *  @return Type    :    void
    **/
    public void MassRollupRevenueCalculation(List<Opportunity> oppList) {
        constants.IS_BY_PASS_SCHEDULES_TRIGGER = false;
        
        oppty = oppList[0];
        utl = new Utility(oppty); 
        CloseDateValue = Date.today();
        oppty.Name = oppty.Name;
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
       	currencyFormate = userInfo.getDefaultCurrency();
        currentMonthlyFiscalYear = new List<CurrentFiscalYearMonthlyRecords>();
        fiscalYearWithSingleCurrency = new List<fiscalYearMonthlyRecordsWithSingleCurrency>();
        
        //Initiliazation
        opportunityLineItemIds = new Set<Id>();
        
        //Loop over oli to get oli id's and total amount
        for(OpportunityLineItem item : [SELECT Id FROM OpportunityLineItem Where OpportunityId IN :oppList]) {
            //Adding oli id's in set
            opportunityLineItemIds.add(item.id);
        }
        
        //Variable to hold query for schedules
        String query = ' ';
        
        //Create dynamic query
        query += 'SELECT  Date__c, Month__c, OpportunityLineItemId__c, RecognizedRevTotal__c, RecognizedRev__c, RecMonth__c, RecYear__c, RecRevWei__c, RevRecOpportunityLineItem__r.Opportunity__r.Id ';
        
        //Check if multi currency enabled
        if(isMultiCurrencyEnabled)
            query += ',CurrencyIsoCode  ';
        
        query += 'from RevRecOpportunityLineItemSchedule__c where External_OpportunityLineItemId__c IN :opportunityLineItemIds WITH SECURITY_ENFORCED order by Date__c ASC ';
        
        //Yearly Schdedules
        List<RevRecOpportunityLineItemSchedule__c> rrOLISsYearly = database.query(query);
        
       
        Map<Id, List<RevRecOpportunityLineItemSchedule__c>> mapOfOppIdWithSchedules = new Map<Id, List<RevRecOpportunityLineItemSchedule__c>>();
        for(RevRecOpportunityLineItemSchedule__c RRLISchedules : rrOLISsYearly) {
            if(!mapOfOppIdWithSchedules.containsKey(RRLISchedules.RevRecOpportunityLineItem__r.Opportunity__r.Id))
                mapOfOppIdWithSchedules.put(RRLISchedules.RevRecOpportunityLineItem__r.Opportunity__r.Id, new List<RevRecOpportunityLineItemSchedule__c>());
            mapOfOppIdWithSchedules.get(RRLISchedules.RevRecOpportunityLineItem__r.Opportunity__r.Id).add(RRLISchedules);
        }
        //Map to hold schedules with month and year as key value to rollup schedules
        Map<String, RevRecOpportunityLineItemSchedule__c> mapStringWithRROLIScheduleYearly = new Map<String, RevRecOpportunityLineItemSchedule__c>();
        Map<Id, List<RevRecOpportunityLineItemSchedule__c>> mapOfOppWithYearlySchedule = new Map<Id, List<RevRecOpportunityLineItemSchedule__c>>();
        Map<Id, List<RevRecOpportunityLineItemSchedule__c>> mapOfOppWithMonthlySchedule = new Map<Id, List<RevRecOpportunityLineItemSchedule__c>>();
        rrOpportunityLineItemSchedules = new List<RevRecOpportunityLineItemSchedule__c>();
        List<Opportunity> listOfOpp = new List<Opportunity>();

        if(mapOfOppIdWithSchedules.values().size() > 0) {
            for(opportunity opp : oppList) {
                //Loop over schedules
                for(RevRecOpportunityLineItemSchedule__c itemYearly :mapOfOppIdWithSchedules.get(opp.Id)) {
                    //Creating unique key vallue for map
                    String mapKeyYearly = opp.Id + '-' + String.valueOf(itemYearly.Date__c.year());
                    
                    //Check if, map contains key then roll up existing with new one
                    if(mapStringWithRROLIScheduleYearly.containsKey(mapKeyYearly)) {
                        //Schedule to hold existing record
                        RevRecOpportunityLineItemSchedule__c existingRROLISchedule = mapStringWithRROLIScheduleYearly.get(mapKeyYearly);
                        
                        //Adding new instance value
                        existingRROLISchedule.RecognizedRev__c += itemYearly.RecognizedRev__c;
                        existingRROLISchedule.RecognizedRevTotal__c += itemYearly.RecognizedRevTotal__c;
                        existingRROLISchedule.RecRevWei__c += itemYearly.RecRevWei__c;
                        existingRROLISchedule.Date__c = itemYearly.Date__c;
                    } else {
                        mapStringWithRROLIScheduleYearly.put(mapKeyYearly, itemYearly);
                        if(!mapOfOppWithYearlySchedule.containsKey(opp.Id))
                            mapOfOppWithYearlySchedule.put(opp.Id, new List<RevRecOpportunityLineItemSchedule__c>());
                        mapOfOppWithYearlySchedule.get(opp.Id).add(itemYearly);
                    }
                }
                //Initiliazation
                recognized = 0.0;
                if(mapStringWithRROLIScheduleYearly.size() > 0 ) {
                    for(RevRecOpportunityLineItemSchedule__c itemYearly :mapStringWithRROLIScheduleYearly.values()) {
                        recognized += itemYearly.RecognizedRev__c;
                    }
                }
                
                //Assgining total values on opportunity
                if(Utility.checkFieldPermission(mapfieldOppResult,'TCV_Actual__c',Constants.PERMISSION_UPDATE)){
                    opp.TCV_Actual__c = recognized;
                }
                
                if(isMultiCurrencyEnabled) {
                    //Checking for null
                    if(opp.TCV_Actual__c != null)
                        oppTotalOpportunity = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), opp.TCV_Actual__c);
                    else 
                        oppTotalOpportunity = oppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                    
                    //Checking for null
                    if(recognized != null)
                        oppTotalOpportunityWei = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), (recognized * opp.Probability) /100);
                    else 
                        oppTotalOpportunityWei = oppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                }
                else {
                    if(opp.TCV_Actual__c != null)
                        oppTotalOpportunityForSingleCurrency = opp.TCV_Actual__c;
                    else 
                        oppTotalOpportunityForSingleCurrency = 0.00;
                    
                    //Checking for null
                    if(recognized != null)
                        oppTotalOpportunityWeiForSingleCurrency = (recognized * opp.Probability) /100;
                    else 
                        oppTotalOpportunityWeiForSingleCurrency = 0.00;
                }
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Opportunity'))
                    listOfOpp.add(opp);
            }
        }
        
        constants.IS_BY_PASS_OPP_TRIGGER = true;
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'Opportunity')) 
           update listOfOpp;
        constants.IS_BY_PASS_OPP_TRIGGER = false;
        
        //Initiliazation
        recognized = 0.0;
        
        //Yearly Schdedules
        List<RevRecOpportunityLineItemSchedule__c> rrOLISsYearlySchedules = database.query(query);
        
        Map<Id, List<RevRecOpportunityLineItemSchedule__c>> mapOfOppIdWithMonthlySchedules = new Map<Id, List<RevRecOpportunityLineItemSchedule__c>>();
        for(RevRecOpportunityLineItemSchedule__c RRLISchedules :rrOLISsYearlySchedules) {
            if(!mapOfOppIdWithMonthlySchedules.containsKey(RRLISchedules.RevRecOpportunityLineItem__r.Opportunity__r.Id))
                mapOfOppIdWithMonthlySchedules.put(RRLISchedules.RevRecOpportunityLineItem__r.Opportunity__r.Id, new List<RevRecOpportunityLineItemSchedule__c>());
            mapOfOppIdWithMonthlySchedules.get(RRLISchedules.RevRecOpportunityLineItem__r.Opportunity__r.Id).add(RRLISchedules);
        }
        //Map to hold schedules with month and year as key value to rollup schedules
        Map<String, RevRecOpportunityLineItemSchedule__c> mapStringWithRROLIScheduleMonthly = new Map<String, RevRecOpportunityLineItemSchedule__c>();
        
        if(mapOfOppIdWithMonthlySchedules.values().size() > 0) {
            for(opportunity opp :oppList) {
                for(RevRecOpportunityLineItemSchedule__c item :mapOfOppIdWithMonthlySchedules.get(opp.Id)) {
                    //Creating unique key vallue for map
                    String mapKey = opp.Id + '-' + String.valueOf(item.Date__c.month()) + '-' + String.valueOf(item.Date__c.year());
                    
                    //Check if, map contains key then roll up existing with new one
                    if(mapStringWithRROLIScheduleMonthly.containsKey(mapKey)) {
                        //Schedule to hold existing record
                        RevRecOpportunityLineItemSchedule__c existingRROLIScheduleMonthly = mapStringWithRROLIScheduleMonthly.get(MapKey);
                        
                        existingRROLIScheduleMonthly.RecognizedRev__c += item.RecognizedRev__c;
                        existingRROLIScheduleMonthly.RecognizedRevTotal__c = item.RecognizedRevTotal__c;
                        existingRROLIScheduleMonthly.RecRevWei__c += item.RecRevWei__c;
                    } else {
                        mapStringWithRROLIScheduleMonthly.put(mapKey, item);
                        if(!mapOfOppWithMonthlySchedule.containsKey(opp.Id))
                            mapOfOppWithMonthlySchedule.put(opp.Id, new List<RevRecOpportunityLineItemSchedule__c>());
                        mapOfOppWithMonthlySchedule.get(opp.Id).add(item);
                    }
                }
                if(mapStringWithRROLIScheduleMonthly.size() > 0) {
                    //Variables
                    transient String schRevRec;
                    transient String schRevRecWei;
                    transient String schRevRecTotal;
                    transient String schYear;
                    transient String schMonth;
                    Date schDate = null;
                    transient Integer sequence = 0;
                    
                    Map<String, Period> mapOfFiscalYear = calculateFiscalYear();
                    
                    //Loop over roll up schdules
                    for(RevRecOpportunityLineItemSchedule__c item :mapStringWithRROLIScheduleMonthly.values()) {
                        //Calculation differred amount for each roll up schedule
                        recognized += item.RecognizedRev__c;
                        
                        //Assign schedule date
                        schDate = item.Date__c;
                        
                        if(item.RecognizedRev__c != null)
                            schRevRec += item.RecognizedRev__c;
                        if(item.RecRevWei__c != null)
                            schRevRecWei += item.RecRevWei__c;
                        if(isMultiCurrencyEnabled) {
                            //Checking for null
                            if(item.RecognizedRev__c != null)
                                schRevRec = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), item.RecognizedRev__c);
                            
                            //Checking for null
                            if(item.RecRevWei__c != null)
                                schRevRecWei = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), item.RecRevWei__c);
                            
                            //Checking for null
                            if(item.RecognizedRevTotal__c != null)
                                schRevRecTotal = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), item.RecognizedRevTotal__c);
                            
                            if(item.RecYear__c != null)
                                schYear = String.valueOf(item.RecYear__c);
                            
                            if(item.RecMonth__c != null)
                                schMonth = String.valueOf(item.RecMonth__c);
                            
                            //Sequence to serilaize recoreds
                            sequence++;
                            for(String periodsList : mapOfFiscalYear.Keyset()) {
                                if(String.valueOf(periodsList) == String.valueOf(schMonth) + '-' + String.valueOf(schYear)) {
                                    currentMonthlyFiscalYear.add(new CurrentFiscalYearMonthlyRecords(schRevRec, schRevRecWei, schYear, schMonth, schDate));
                                }
                            }
                        }
                        else {
                            rrOpportunityLineItemSchedules.add(item); //Adding schedules if multi currency is not enabled
                        }  
                    }
                    if(rrOpportunityLineItemSchedules.size() > 0) {
                        transient Decimal totalSchRecRev = 0.00;
                        transient Decimal totalSchRecRevWei = 0.00;
                        transient Decimal totalSchRevRecTotal = 0.00;
                        //Loop over rrOpportunityLineItemSchedules
                        for(RevRecOpportunityLineItemSchedule__c sch : rrOpportunityLineItemSchedules) {
                            totalSchRecRev = sch.RecognizedRev__c; 
                            totalSchRecRevWei = sch.RecRevWei__c;
                            totalSchRevRecTotal = sch.RecognizedRevTotal__c;
                            sequence++;
                            
                            schDate = sch.Date__c;
                            
                            if(sch.RecYear__c != null)
                                schYear = String.valueOf(sch.RecYear__c);
                            
                            if(sch.RecMonth__c != null)
                                schMonth = String.valueOf(sch.RecMonth__c);
                            for(String periodsList :mapOfFiscalYear.Keyset()) {
                                if(String.valueOf(periodsList) == String.valueOf(schMonth) + '-' + String.valueOf(schYear)) {
                                    fiscalYearWithSingleCurrency.add(new fiscalYearMonthlyRecordsWithSingleCurrency(totalSchRecRev, totalSchRecRevWei, schYear, schMonth, schDate));
                                }
                            }
                        }
                    }
                }
            }
        }
        Map<Id, Set<Yearly_Revenue_Rollups__c>> mapOfIdWithYearlyRollup = new Map<Id, Set<Yearly_Revenue_Rollups__c>>();
        for(Yearly_Revenue_Rollups__c yearRecords : [SELECT Id, Name, Year__c, Opportunity__c, Yearly_Revenue_Date__c, Yearly_Forecasted_Revenue_Weighted__c,Yearly_Actual_Revenue__c, Yearly_Forecasted_Revenue__c
                                                     FROM Yearly_Revenue_Rollups__c
                                                     WHERE Opportunity__c =: oppty.Id 
                                                     ORDER By Year__c ASC]) 
        {
            if(!mapOfIdWithYearlyRollup.containsKey(yearRecords.Opportunity__c))
                mapOfIdWithYearlyRollup.put(yearRecords.Opportunity__c, new Set<Yearly_Revenue_Rollups__c>());
            mapOfIdWithYearlyRollup.get(yearRecords.Opportunity__c).add(yearRecords);
        } 
        

        //Method calling
        insertAndUpdateYearlyAndMonthlyRecords(mapOfOppWithYearlySchedule, mapOfIdWithYearlyRollup, mapOfOppWithMonthlySchedule);
    }
    
    /**
    *  @Description    :    This method is used to insert, update and delete the Yearly Rollup Records
    *
    *  @args           :    Map<Id, List<RevRecOpportunityLineItemSchedule__c>>,Map<Id, Set<Yearly_Revenue_Rollups__c>>,
    *
    *  @return Type    :    Map<Id, Map<String, Id>>
    **/
    public void insertAndUpdateYearlyAndMonthlyRecords(Map<Id, List<RevRecOpportunityLineItemSchedule__c>> mapOfOppWithYearlySchedule, Map<Id, Set<Yearly_Revenue_Rollups__c>> mapOfIdWithSetYearlyRollup, Map<Id, List<RevRecOpportunityLineItemSchedule__c>> mapOfOppWithMonthlySchedule) {
        //list to yearly rollup to upsert
        listOfYearlyRollupToInsert = new List<Yearly_Revenue_Rollups__c>();
        
        //list of yearly rollup to be deleted
        List<Yearly_Revenue_Rollups__c> listYearlyToBeDeleted = new List<Yearly_Revenue_Rollups__c>();
        Map<Id, Map<String, Id>> mapofOppIDWithYearlyIdAndString = new Map<Id, Map<String, Id>>();
        listOfYearlyWrapper = new List<yearlyWrapper>();
        
        for(Id oppId : mapOfOppWithYearlySchedule.Keyset()) {
            List<Yearly_Revenue_Rollups__c> listOfYearlyIDs = new List<Yearly_Revenue_Rollups__c>();
            if(mapOfIdWithSetYearlyRollup.containskey(oppId)) {
                listOfYearlyIDs.addAll(mapOfIdWithSetYearlyRollup.get(oppId));
            }
            for(RevRecOpportunityLineItemSchedule__c revRec :mapOfOppWithYearlySchedule.get(OppId)) {
                
                //if condition for update case
                //else condition for insertion case
                if(listOfYearlyIDs.size() > 0) {
                    Yearly_Revenue_Rollups__c yearlyRollupRecord = new Yearly_Revenue_Rollups__c();
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Id',Constants.PERMISSION_ACCESS))
                        yearlyRollupRecord.Id = listOfYearlyIDs [0].Id;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Name',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Name = revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Opportunity__c = oppId;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Year__c = revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Yearly_Revenue_Date__c = revRec.Date__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)){
                           if(revRec.Date__c <= System.TODAY())
                               yearlyRollupRecord.Yearly_Actual_Revenue__c = revRec.RecognizedRev__c;
                           else if(revRec.Date__c.Year() == System.TODAY().Year()) {
                               for(RevRecOpportunityLineItemSchedule__c revRecMonthly : mapOfOppWithMonthlySchedule.get(oppId)) {
                                   if(revRecMonthly.Date__c.Year() == System.TODAY().Year() && revRecMonthly.Date__c < System.TODAY()) {
                                       yearlyRollupRecord.Yearly_Actual_Revenue__c =  (yearlyRollupRecord.Yearly_Actual_Revenue__c != null ? yearlyRollupRecord.Yearly_Actual_Revenue__c : 0)+ (revRecMonthly.RecognizedRev__c != null ? revRecMonthly.RecognizedRev__c : 0);
                                   }
                                   else if(yearlyRollupRecord.Yearly_Actual_Revenue__c == null)
                                       yearlyRollupRecord.Yearly_Actual_Revenue__c = 0;
                               }
                           }
                           else 
                               yearlyRollupRecord.Yearly_Actual_Revenue__c = null;
                       }
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Yearly_Forecasted_Revenue_Weighted__c = revRec.RecRevWei__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Yearly_Forecasted_Revenue__c = revRec.RecognizedRev__c;
                    
                    if(isMultiCurrencyEnabled)
                        yearlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Yearly_Revenue_Rollups__c'))
                        listOfYearlyRollupToInsert.add(yearlyRollupRecord);
                    listOfYearlyIDs.remove(0);
                } else {
                    Yearly_Revenue_Rollups__c yearlyRollupRecord = new Yearly_Revenue_Rollups__c();
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Name',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Name = revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Opportunity__c = oppId;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Year__c = revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Yearly_Revenue_Date__c = revRec.Date__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)){
                           if(revRec.Date__c < System.TODAY())
                               yearlyRollupRecord.Yearly_Actual_Revenue__c = revRec.RecognizedRev__c;
                           else if(revRec.Date__c.Year() == System.TODAY().Year()) {
                               for(RevRecOpportunityLineItemSchedule__c revRecMonthly : mapOfOppWithMonthlySchedule.get(oppId)) {
                                   if(revRecMonthly.Date__c.Year() == System.TODAY().Year() && revRecMonthly.Date__c < System.TODAY()) {
                                       yearlyRollupRecord.Yearly_Actual_Revenue__c =  (yearlyRollupRecord.Yearly_Actual_Revenue__c != null ? yearlyRollupRecord.Yearly_Actual_Revenue__c : 0)+ (revRecMonthly.RecognizedRev__c != null ? revRecMonthly.RecognizedRev__c : 0);
                                   }
                                   else if(yearlyRollupRecord.Yearly_Actual_Revenue__c == null)
                                       yearlyRollupRecord.Yearly_Actual_Revenue__c = 0;
                               }
                           }
                           else 
                               yearlyRollupRecord.Yearly_Actual_Revenue__c = null;
                       }
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Yearly_Forecasted_Revenue_Weighted__c = revRec.RecRevWei__c;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Yearly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Yearly_Forecasted_Revenue__c = revRec.RecognizedRev__c;
                    if(isMultiCurrencyEnabled)
                        yearlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Yearly_Revenue_Rollups__c'))
                        listOfYearlyRollupToInsert.add(yearlyRollupRecord);
                }
            }
            listYearlyToBeDeleted.addAll(listOfYearlyIDs);
        }
        
        List<Period> listOfPeriod = [SELECT FiscalYearSettings.Name, StartDate, EndDate FROM Period WHERE Type = 'Year' And FiscalYearSettings.Name >= '2019' And FiscalYearSettings.Name <= '2020'];
        if(listOfPeriod[0].StartDate.year() != listOfPeriod[0].EndDate.year()) {
            IsHavingFiscalYear = true;
            for(Yearly_Revenue_Rollups__c yR : listOfYearlyRollupToInsert) {
                if(!mapofOppIDWithYearlyIdAndString.containsKey(yR.Opportunity__c)) {
                    mapofOppIDWithYearlyIdAndString.put(yR.Opportunity__c, new Map<String, Id>());
                    if(!mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).containsKey(yR.Year__c))
                        mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).put(yR.Year__c, yR.id);
                }
                else{
                    mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).put(yR.Year__c, yR.id);
                }
            }
        }
        else {
            IsHavingFiscalYear = false;
            if(!listYearlyToBeDeleted.isEmpty() && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'Yearly_Revenue_Rollups__c')))
                delete listYearlyToBeDeleted;
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Yearly_Revenue_Rollups__c')){
                if(listOfYearlyRollupToInsert.size() > 0)
                    upsert listOfYearlyRollupToInsert;
            }
            
            if(isMultiCurrencyEnabled) {
                
                String Name;
                Id oppValue;
                String yearValue;
                Date dateValue;
                String yearlyActualValue; 
                String yearlyForecastedValue;
                String yearlyForecastedWeightedvalue;
                
                for(Yearly_Revenue_Rollups__c yR : listOfYearlyRollupToInsert) {
                    Name = yR.Name;
                    oppValue = yR.Opportunity__c;
                    yearValue = yR.Year__c;
                    dateValue = yR.Yearly_Revenue_Date__c;
                    if(yR.Yearly_Actual_Revenue__c != null)
                        yearlyActualValue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), yR.Yearly_Actual_Revenue__c);
                    
                    if(yR.Yearly_Forecasted_Revenue__c != null)
                        yearlyForecastedValue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), yR.Yearly_Forecasted_Revenue__c);
                    
                    if(yR.Yearly_Forecasted_Revenue_Weighted__c != null)
                        yearlyForecastedWeightedvalue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), yR.Yearly_Forecasted_Revenue_Weighted__c);
                    
                    listOfYearlyWrapper.add(new yearlyWrapper(yearValue, dateValue, yearlyActualValue, yearlyForecastedValue, yearlyForecastedWeightedvalue));
                }            
            }
            
            if(listOfYearlyRollupToInsert.size() > 0) {
                for(Yearly_Revenue_Rollups__c yR : listOfYearlyRollupToInsert) {
                    if(!mapofOppIDWithYearlyIdAndString.containsKey(yR.Opportunity__c)) {
                        mapofOppIDWithYearlyIdAndString.put(yR.Opportunity__c, new Map<String, Id>());
                        if(!mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).containsKey(yR.Year__c))
                            mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).put(yR.Year__c, yR.id);
                    }
                    else{
                        mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).put(yR.Year__c, yR.id);
                    }
                }
            }
            
        }
        
        Map<Id, Set<Monthly_Revenue_Rollups__c>> mapOfIdWithMonthlyRollup = new Map<Id, Set<Monthly_Revenue_Rollups__c>>();
        for(Monthly_Revenue_Rollups__c monthlyRecords :[SELECT id, Name, Month__c, Year__c, Monthly_Revenue_Date__c, Opportunity__c, Yearly_Revenue_Rollup__c, Monthly_Actual_Revenue__c,Monthly_Forecasted_Revenue_Weighted__c, Monthly_Forecasted_Revenue__c
                                                        FROM Monthly_Revenue_Rollups__c
                                                        WHERE Opportunity__c =: oppty.Id 
                                                        ORDER BY Monthly_Revenue_Date__c ASC]) 
        {
            if(!mapOfIdWithMonthlyRollup.containsKey(monthlyRecords.Opportunity__c))
                mapOfIdWithMonthlyRollup.put(monthlyRecords.Opportunity__c, new Set<Monthly_Revenue_Rollups__c>());
            mapOfIdWithMonthlyRollup.get(monthlyRecords.Opportunity__c).add(monthlyRecords);
        }  
        
        List<Monthly_Revenue_Rollups__c> listOfMonthlyRollupToInsert = new List<Monthly_Revenue_Rollups__c>();
        List<Monthly_Revenue_Rollups__c> listOfMonthlyRollupToBeDelete = new List<Monthly_Revenue_Rollups__c>();
        
        for(Id oppId :mapOfOppWithMonthlySchedule.Keyset()) {
            List<Monthly_Revenue_Rollups__c> listOfMonthlyIDs = new List<Monthly_Revenue_Rollups__c>();
            if(mapOfIdWithMonthlyRollup.containskey(oppId)) {
                listOfMonthlyIDs.addAll(mapOfIdWithMonthlyRollup.get(oppId));
            }
            for(RevRecOpportunityLineItemSchedule__c revRec : mapOfOppWithMonthlySchedule.get(OppId)) {
                
                //if condition for insertion case 
                //else condition for updattion case
                if(listOfMonthlyIDs.size() > 0) {
                    Monthly_Revenue_Rollups__c monthlyRollupRecord = new Monthly_Revenue_Rollups__c();
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Name',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Name = revRec.RecMonth__c + '-' + revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Id',Constants.PERMISSION_ACCESS))
                        monthlyRollupRecord.Id = listOfMonthlyIDs [0].Id;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Opportunity__c = oppId;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Year__c = revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Month__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Month__c = Decimal.valueOf(revRec.Month__c);
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Monthly_Revenue_Date__c = revRec.Date__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Yearly_Revenue_Rollup__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Yearly_Revenue_Rollup__c = mapofOppIDWithYearlyIdAndString.get(oppId).get(revRec.RecYear__c);
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)){
                           if(revRec.Date__c < System.TODAY())
                               monthlyRollupRecord.Monthly_Actual_Revenue__c = revRec.RecognizedRev__c;
                           else 
                               monthlyRollupRecord.Monthly_Actual_Revenue__c = null;
                       }
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Monthly_Forecasted_Revenue_Weighted__c = revRec.RecRevWei__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Monthly_Forecasted_Revenue__c = revRec.RecognizedRev__c;
                    if(isMultiCurrencyEnabled)
                        monthlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Monthly_Revenue_Rollups__c'))
                        listOfMonthlyRollupToInsert.add(monthlyRollupRecord);
                    listOfMonthlyIDs.remove(0);
                } else {
                    Monthly_Revenue_Rollups__c monthlyRollupRecord = new Monthly_Revenue_Rollups__c();
                    
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Name',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Name = revRec.RecMonth__c + '-' + revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Opportunity__c = oppId;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Year__c = revRec.RecYear__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Month__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Month__c = Decimal.valueOf(revRec.Month__c);
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Monthly_Revenue_Date__c = revRec.Date__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Yearly_Revenue_Rollup__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Yearly_Revenue_Rollup__c = mapofOppIDWithYearlyIdAndString.get(oppId).get(revRec.RecYear__c);
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)){
                           if(revRec.Date__c < System.TODAY())
                               monthlyRollupRecord.Monthly_Actual_Revenue__c = revRec.RecognizedRev__c;
                           else 
                               monthlyRollupRecord.Monthly_Actual_Revenue__c = null;
                       }
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Monthly_Forecasted_Revenue_Weighted__c = revRec.RecRevWei__c;
                    if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Monthly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        monthlyRollupRecord.Monthly_Forecasted_Revenue__c = revRec.RecognizedRev__c;
                    if(isMultiCurrencyEnabled)
                        monthlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Monthly_Revenue_Rollups__c'))
                        listOfMonthlyRollupToInsert.add(monthlyRollupRecord);
                }
            }
            listOfMonthlyRollupToBeDelete.addAll(listOfMonthlyIDs);
        }
        if(listOfMonthlyRollupToBeDelete.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'Monthly_Revenue_Rollups__c')))
            delete listOfMonthlyRollupToBeDelete;
        
        if(listOfPeriod[0].StartDate.year() != listOfPeriod[0].EndDate.year()) {
            IsHavingFiscalYear = true;
        }
        else{
            IsHavingFiscalYear = false;
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Monthly_Revenue_Rollups__c')){
                if(listOfMonthlyRollupToInsert.size() > 0)
                    upsert listOfMonthlyRollupToInsert;
            }
        }
        
        mapOfYearlyIdWithMonthlyRollups = new Map<String, List<Monthly_Revenue_Rollups__c>>();
        Map<Id, Map<String, List<Monthly_Revenue_Rollups__c>>> mapOfOppWithYearlyIdWithMonthlyRollupsFY = new Map<Id, Map<String, List<Monthly_Revenue_Rollups__c>>>();
       
        for(Monthly_Revenue_Rollups__c monthly : listOfMonthlyRollupToInsert) { 
            if(!mapOfOppWithYearlyIdWithMonthlyRollupsFY.containsKey(monthly.Opportunity__c)){
                mapOfOppWithYearlyIdWithMonthlyRollupsFY.put(monthly.Opportunity__c, new Map<String, List<Monthly_Revenue_Rollups__c>>());
            }
            if(!mapOfOppWithYearlyIdWithMonthlyRollupsFY.get(monthly.Opportunity__c).containsKey(monthly.Year__c+'-'+monthly.Opportunity__c)){
                mapOfOppWithYearlyIdWithMonthlyRollupsFY.get(monthly.Opportunity__c).put(monthly.Year__c+'-'+monthly.Opportunity__c, new List<Monthly_Revenue_Rollups__c>());
            }
            mapOfOppWithYearlyIdWithMonthlyRollupsFY.get(monthly.Opportunity__c).get(monthly.Year__c+'-'+monthly.Opportunity__c).add(monthly);  
        }
        
        for(Yearly_Revenue_Rollups__c yearly :[SELECT id, Name, (SELECT id, Name, Month__c, Year__c, Monthly_Revenue_Date__c, Opportunity__c, Yearly_Revenue_Rollup__c, Yearly_Revenue_Rollup__r.Name,
                                                                 Monthly_Actual_Revenue__c, Monthly_Forecasted_Revenue__c, Monthly_Forecasted_Revenue_Weighted__c                                                                 
                                                                 FROM Monthly_Revenue_Rollups__r
                                                                 WHERE Opportunity__c =: oppty.Id 
                                                                 ORDER By Monthly_Revenue_Date__c ASC)
                                               FROM Yearly_Revenue_Rollups__c WHERE Opportunity__c =: oppty.Id ORDER By Year__c ASC]) 
        {
            for(Monthly_Revenue_Rollups__c monthly :yearly.Monthly_Revenue_Rollups__r) {
                if(!mapOfYearlyIdWithMonthlyRollups.containsKey(monthly.Yearly_Revenue_Rollup__r.Name))
                    mapOfYearlyIdWithMonthlyRollups.put(monthly.Yearly_Revenue_Rollup__r.Name, new List<Monthly_Revenue_Rollups__c>());
                mapOfYearlyIdWithMonthlyRollups.get(monthly.Yearly_Revenue_Rollup__r.Name).add(monthly);
            }  
        }
        
        Map<Id, List<Yearly_Revenue_Rollups__c>> mapOfIdWithYearlyRollupFY = new Map<Id, List<Yearly_Revenue_Rollups__c>>();
        for(Yearly_Revenue_Rollups__c yearRecords : [SELECT id, Name, Year__c, Yearly_Revenue_Date__c, Opportunity__c, Yearly_Forecasted_Revenue_Weighted__c, Yearly_Actual_Revenue__c, Yearly_Forecasted_Revenue__c
                                                     FROM Yearly_Revenue_Rollups__c
                                                     WHERE Opportunity__c =: oppty.Id 
                                                     ORDER By Year__c ASC]) 
        {
            if(!mapOfIdWithYearlyRollupFY.containsKey(yearRecords.Opportunity__c))
                mapOfIdWithYearlyRollupFY.put(yearRecords.Opportunity__c, new List<Yearly_Revenue_Rollups__c>());
            mapOfIdWithYearlyRollupFY.get(yearRecords.Opportunity__c).add(yearRecords);
        }
        
        //Checking of fiscal year in org
        if(IsHavingFiscalYear == true)
            showMonthlyAccordingToFiscalYear(mapOfOppWithYearlyIdWithMonthlyRollupsFY, mapOfIdWithYearlyRollupFY, mapOfIdWithMonthlyRollup);
    }
    
    /**
    *  @Description    :    This method is used to show the current year records which click on specific year on page
    *
    *  @args           :	    
    *
    *  @return Type    :    void
    **/
    public void getMonthlyRevnueRollUpAccordingSelectedYear() {
        String selYear = Apexpages.currentPage().getParameters().get('selectedYear');
        monthlySelectedRevenueRollups = new List<Monthly_Revenue_Rollups__c>();
        listOfMonthlyWrapper = new List<monthlyWrapper>();
        
        for(Monthly_Revenue_Rollups__c monthlyRevenueRollup : mapOfYearlyIdWithMonthlyRollups.get(selYear)) {  
            if(opportunityId == monthlyRevenueRollup.Opportunity__c) {
                Monthly_Revenue_Rollups__c monthly = new Monthly_Revenue_Rollups__c();
                
                monthly.Name = monthlyRevenueRollup.Name;
                monthly.Month__c = monthlyRevenueRollup.Month__c;
                monthly.Year__c = monthlyRevenueRollup.Year__c;
                monthly.Monthly_Revenue_Date__c = monthlyRevenueRollup.Monthly_Revenue_Date__c;
                monthly.Monthly_Actual_Revenue__c = monthlyRevenueRollup.Monthly_Actual_Revenue__c;
                monthly.Monthly_Forecasted_Revenue__c = monthlyRevenueRollup.Monthly_Forecasted_Revenue__c;
                monthly.Monthly_Forecasted_Revenue_Weighted__c = monthlyRevenueRollup.Monthly_Forecasted_Revenue_Weighted__c;
                
                monthlySelectedRevenueRollups.add(monthly);
            }
        }
        if(isMultiCurrencyEnabled) {
            String Name;
            Decimal monthValue = 0;
            String yearValue;
            Date dateValue;
            String monthlyActualValue; 
            String monthlyForecastedValue;
            String monthlyForecastedWeightedvalue;
            
            for(Monthly_Revenue_Rollups__c mR : monthlySelectedRevenueRollups) {
                Name = mR.Name;
                monthValue = mR.Month__c;
                yearValue = mR.Year__c;
                dateValue = mR.Monthly_Revenue_Date__c;
                if(mR.Monthly_Actual_Revenue__c != null)
                    monthlyActualValue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), mR.Monthly_Actual_Revenue__c);
                
                if(mR.Monthly_Forecasted_Revenue__c != null)
                    monthlyForecastedValue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), mR.Monthly_Forecasted_Revenue__c);
                
                if(mR.Monthly_Forecasted_Revenue_Weighted__c != null)
                    monthlyForecastedWeightedvalue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), mR.Monthly_Forecasted_Revenue_Weighted__c);
                
                listOfMonthlyWrapper.add(new monthlyWrapper(monthValue, yearValue, dateValue, monthlyActualValue, monthlyForecastedValue, monthlyForecastedWeightedvalue));
            }  
        }
    }
    
    /**
    *  @Description    :   This method is used to back on opportunity
    *
    *  @args           :   void
    * 
    *  @return Type    :   PageReference
    **/
    public PageReference cancel() { return new PageReference('/' + opportunityId); }
    
    /**
    *  @Description			:   This method is used to calculate Fiscal year
    *
    *  @args				:   Map<String, Period>
    *
    *  @return Type			:    void
    **/
    public Map<String, Period> calculateFiscalYear() {
        Map<String, Period> fiscalMap = new Map<String, Period>();
        Period period = [SELECT FiscalYearSettings.Name, Type, StartDate, EndDate FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY];
        Map<Integer, String> monthsMap = new Map<Integer, String> {
            	1    => '1', 
                2    => '2', 
                3    => '3', 
                4    => '4', 
                5    => '5', 
                6    => '6', 
                7    => '7',  
                8    => '8', 
                9    => '9', 
                10    => '10', 
                11    => '11', 
                12    => '12'
                };
                    
        Integer startDtMonth = period.StartDate.month();
        Integer endDtMonth = period.EndDate.month();
        
        List<String> lstStartDate = new List<String>();
        List<String> lstEndDate = new List<String>();
        List<String> sortedEndDate = new List<String>();
        
        for(Integer i = startDtMonth; i <= 12; i ++) {
            lstStartDate.add(monthsMap.get(i) + '-' + period.StartDate.year());
        }
        
        for(Integer i = endDtMonth; i >= 1; i --) {
            lstEndDate.add(monthsMap.get(i) + '-' + period.EndDate.year());
        }
        
        for(Integer i = lstEndDate.size() -1; i >= 0; i --) {
            sortedEndDate.add(lstEndDate [i]);
        }
        
        List<String> mergedList = new List<String>();
        mergedList.addAll(lstStartDate);
        mergedList.addAll(sortedEndDate);
        
        for(String mergedListVar :mergedList) {
            if(!fiscalMap.containsKey(mergedListVar)) {
                fiscalMap.put(mergedListVar, period);
            }
        }
        return fiscalMap;
    }
    
    /**
    *  @Description    :    This method is used to calculate the fiscal year and the range of fiscal year
    *
    *  @args           :	Integer, Integer	    
    *
    *  @return Type    :    Map<String, List<String>>
    **/
    public Map<String, List<String>> calculationOfFiscalYear(Integer startYear, Integer endYear) {
        
        Map<String, List<String>> fiscalMap = new Map<String, List<String>>();
        Map<String, List<String>> combinedFiscalMap = new Map<String, List<String>>();
        Integer startYr = startYear - 1;
        Integer endYr = endYear + 1;
        
        for(Period pd : [SELECT FiscalYearSettings.Name, StartDate, EndDate FROM Period WHERE Type = 'Month' And FiscalYearSettings.Name >= :String.valueOf(startYr) And FiscalYearSettings.Name <= :String.valueOf(endYr) order By EndDate]) {
            if(!fiscalMap.containsKey(pd.FiscalYearSettings.Name))
                fiscalMap.put(pd.FiscalYearSettings.Name, new List<String>());
            fiscalMap.get(pd.FiscalYearSettings.Name).add(pd.EndDate.Month() + '-' + pd.EndDate.Year());
        }
        
        for(Period pd : [SELECT FiscalYearSettings.Name, StartDate, EndDate FROM Period WHERE Type = 'Year' And FiscalYearSettings.Name >= :String.valueOf(startYr) And FiscalYearSettings.Name <= :String.valueOf(endYr)]){
            if(!combinedFiscalMap.containsKey(pd.startDate.Year() +'-'+ pd.EndDate.Year()))
                combinedFiscalMap.put((pd.startDate.Year() +'-'+ pd.EndDate.Year()), fiscalMap.get(pd.FiscalYearSettings.Name));
        }
        return combinedFiscalMap;
    }
    
    /**
    *  @Description    :    This method is used to show yearly and monthly records according to fiscal year
    *
    *  @args           :	Map<Id, Map<String, List<Monthly_Revenue_Rollups__c>>>	    
    *
    *  @return Type    :    void
    **/
    public void showMonthlyAccordingToFiscalYear(Map<Id, Map<String, List<Monthly_Revenue_Rollups__c>>> mapOfOppWithYearlyIdWithMonthlyRollups, Map<Id, List<Yearly_Revenue_Rollups__c>> mapOfIdWithYearlyRollupFY, Map<Id, Set<Monthly_Revenue_Rollups__c>> mapOfIdWithMonthlyRollup) {
        Integer minYear = 0, maxYear = 0;
        
        for(Id opportunityId :mapOfOppWithYearlyIdWithMonthlyRollups.keyset()) {
            for(List<Monthly_Revenue_Rollups__c> monthlyValues : mapOfOppWithYearlyIdWithMonthlyRollups.get(opportunityId).values()) {
                minYear = Integer.valueOf(monthlyValues [0].Year__c);
                for (integer i = 0; i < mapOfOppWithYearlyIdWithMonthlyRollups.get(opportunityId).size(); i ++) {
                    if(i < monthlyValues.size()){
                        if(Integer.valueOf(monthlyValues [i].Year__c) > minYear)
                        minYear = Integer.valueOf(monthlyValues [i].Year__c);
                    }
                }
                break;
            }
        }
        for(Id opportunityId :mapOfOppWithYearlyIdWithMonthlyRollups.keyset()) {
            for(List<Monthly_Revenue_Rollups__c> monthlyValues :mapOfOppWithYearlyIdWithMonthlyRollups.get(opportunityId).values()) {
                maxYear = Integer.valueOf(monthlyValues [0].Year__c);
                for (integer i = 0; i < mapOfOppWithYearlyIdWithMonthlyRollups.values().size(); i ++) {
                    if(i < monthlyValues.size()){
                    if(Integer.valueOf(monthlyValues [i].Year__c) > maxYear)
                        maxYear = Integer.valueOf(monthlyValues [i].Year__c);
                    }
                }
            }
        }   
        
        Map<String, List<String>> mapofFiscalYear = calculationOfFiscalYear(minYear, maxYear);
        Map<Id, Map<String, List<Monthly_Revenue_Rollups__c>>> mapWithOppIdWithYearWithMonthlyRevenueFY = new Map<Id, Map<String, List<Monthly_Revenue_Rollups__c>>>();
        Map<String, List<Monthly_Revenue_Rollups__c>> mapOfYearWithMonthlyRevenueFY = new Map<String, List<Monthly_Revenue_Rollups__c>>();
        Map<Id, List<Monthly_Revenue_Rollups__c>> mapWithOppIdWithYearWithYearlyRevenueFY = new Map<Id, List<Monthly_Revenue_Rollups__c>>();
        Map<String, Monthly_Revenue_Rollups__c> mapOfYearWithRollupMonthlyRevenueFY = new Map<String, Monthly_Revenue_Rollups__c>();
        Map<Id, Map<String, Id>> mapofOppIDWithYearlyIdAndStringFY = new Map<Id, Map<String, Id>>();
                
        for(Id oppId : mapOfOppWithYearlyIdWithMonthlyRollups.keyset()) {
            for(String years : mapofFiscalYear.keyset()) {
                String firstYear = years.split('-') [0];
                String nextYear = years.split('-') [1];
                for(String monthYearValues : mapofFiscalYear.get(years)) {
                    for(String yearId : mapOfOppWithYearlyIdWithMonthlyRollups.get(oppId).keyset()) {
                        for(Monthly_Revenue_Rollups__c monthly : mapOfOppWithYearlyIdWithMonthlyRollups.get(oppId).get(yearId)) {
                            if(monthly.Year__c == firstYear) {
                                if(monthYearValues == monthly.Month__c +'-'+ monthly.Year__c) {
                                    if(!mapOfYearWithMonthlyRevenueFY.containsKey(oppId +'-'+firstYear +'-'+ nextYear)) 
                                        mapOfYearWithMonthlyRevenueFY.put(oppId +'-'+firstYear +'-'+ nextYear, new List<Monthly_Revenue_Rollups__c>());
                                    mapOfYearWithMonthlyRevenueFY.get(oppId +'-'+firstYear +'-'+ nextYear).add(monthly);
                                }
                            }
                            if(monthly.Year__c == nextYear) {
                                if(monthYearValues == monthly.Month__c +'-'+ monthly.Year__c) {
                                    if(!mapOfYearWithMonthlyRevenueFY.containsKey(oppId +'-'+firstYear +'-'+ nextYear)) 
                                        mapOfYearWithMonthlyRevenueFY.put(oppId +'-'+firstYear +'-'+ nextYear, new List<Monthly_Revenue_Rollups__c>());
                                    mapOfYearWithMonthlyRevenueFY.get(oppId +'-'+firstYear +'-'+ nextYear).add(monthly);
                                }
                            }
                        }
                    }
                }
            }
            
            if(!mapWithOppIdWithYearWithMonthlyRevenueFY.containsKey(oppId))
                mapWithOppIdWithYearWithMonthlyRevenueFY.put(oppId, mapOfYearWithMonthlyRevenueFY);

            if(mapOfYearWithMonthlyRevenueFY.size() > 0) {
                for(String combinedYears : mapOfYearWithMonthlyRevenueFY.keyset()) {
                     for(Monthly_Revenue_Rollups__c monthlyRevenue : mapOfYearWithMonthlyRevenueFY.get(combinedYears)) {
                        if(!mapOfYearWithRollupMonthlyRevenueFY.containsKey(combinedYears))
                            mapOfYearWithRollupMonthlyRevenueFY.put(combinedYears, new Monthly_Revenue_Rollups__c());
                        
                        mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).name = combinedYears.substringAfter('-');
                        mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Year__c = combinedYears.substringAfter('-');
                        mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Revenue_Date__c = monthlyRevenue.Monthly_Revenue_Date__c;
                        if(monthlyRevenue.Monthly_Actual_Revenue__c != null)
                            mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Actual_Revenue__c =  (monthlyRevenue.Monthly_Actual_Revenue__c != null ? monthlyRevenue.Monthly_Actual_Revenue__c : 0)+ (mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Actual_Revenue__c != null ? mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Actual_Revenue__c : 0);
                        else {
                            String fiscalYears = combinedYears.substringAfter('-');
                            Integer year = Integer.valueOf(fiscalYears.split('-')[1]);
                            if(year == System.today().year())
                                mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Actual_Revenue__c =  (monthlyRevenue.Monthly_Actual_Revenue__c != null ? monthlyRevenue.Monthly_Actual_Revenue__c : 0)+ (mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Actual_Revenue__c != null ? mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Actual_Revenue__c : 0);
                        }
                        if(monthlyRevenue.Monthly_Forecasted_Revenue__c != null)
                            mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Forecasted_Revenue__c = (monthlyRevenue.Monthly_Forecasted_Revenue__c != null ? monthlyRevenue.Monthly_Forecasted_Revenue__c : 0) + (mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Forecasted_Revenue__c != null ? mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Forecasted_Revenue__c : 0);
                        if(monthlyRevenue.Monthly_Forecasted_Revenue_Weighted__c != null)
                            mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Forecasted_Revenue_Weighted__c =  (monthlyRevenue.Monthly_Forecasted_Revenue_Weighted__c != null ?  monthlyRevenue.Monthly_Forecasted_Revenue_Weighted__c : 0) + (mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Forecasted_Revenue_Weighted__c != null ? mapOfYearWithRollupMonthlyRevenueFY.get(combinedYears).Monthly_Forecasted_Revenue_Weighted__c: 0 );
                    }
                }
            }	
            if(!mapWithOppIdWithYearWithYearlyRevenueFY.containsKey(oppId))
                mapWithOppIdWithYearWithYearlyRevenueFY.put(oppId, new List<Monthly_Revenue_Rollups__c>());
            mapWithOppIdWithYearWithYearlyRevenueFY.get(oppId).addAll(mapOfYearWithRollupMonthlyRevenueFY.values());
        } 
       
        //Method Calling
        mapofOppIDWithYearlyIdAndStringFY = showUpdatedYearlyRecords(mapWithOppIdWithYearWithYearlyRevenueFY, mapOfIdWithYearlyRollupFY);
        showUpdatedMonthlyRecords(mapWithOppIdWithYearWithMonthlyRevenueFY, mapofOppIDWithYearlyIdAndStringFY, mapOfIdWithMonthlyRollup);
    }
    
    /**
    *  @Description    :    This method is used to show updated yearly records according to fiscal year
    *
    *  @args           :	Map<Id, List<Monthly_Revenue_Rollups__c>, Map<Id, Set<Yearly_Revenue_Rollups__c>>	    
    *
    *  @return Type    :    Map<Id, Map<String, Id>>
    **/
    public Map<Id, Map<String, Id>> showUpdatedYearlyRecords(Map<Id, List<Monthly_Revenue_Rollups__c>> mapWithOppIdWithYearWithYearlyRevenueFY, Map<Id, List<Yearly_Revenue_Rollups__c>> mapOfIdWithSetYearlyRollup) {
        Map<Id, Map<String, Id>> mapofOppIDWithYearlyIdAndString = new Map<Id, Map<String, Id>>();
        yearlyRollupsFY = new List<Yearly_Revenue_Rollups__c>();
        List<Yearly_Revenue_Rollups__c> listYearlyToBeDeleted = new List<Yearly_Revenue_Rollups__c>();
        
        for(Id oppId : mapWithOppIdWithYearWithYearlyRevenueFY.Keyset()) {
            
            List<Yearly_Revenue_Rollups__c> listOfYearlyIDs = new List<Yearly_Revenue_Rollups__c>();
            if(mapOfIdWithSetYearlyRollup.containskey(oppId)) {
                listOfYearlyIDs.addAll(mapOfIdWithSetYearlyRollup.get(oppId));
            }
            for(Monthly_Revenue_Rollups__c monthly : mapWithOppIdWithYearWithYearlyRevenueFY.get(oppId)) {
                if(listOfYearlyIDs.size() > 0) {
                    Yearly_Revenue_Rollups__c yearlyRollupRecord = new Yearly_Revenue_Rollups__c();
                    
                    yearlyRollupRecord.Id = listOfYearlyIDs [0].Id;
                    yearlyRollupRecord.Name = monthly.Name;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Opportunity__c = oppId;
                    yearlyRollupRecord.Year__c = monthly.Year__c;
                    yearlyRollupRecord.Yearly_Revenue_Date__c = monthly.Monthly_Revenue_Date__c; 
                    yearlyRollupRecord.Yearly_Actual_Revenue__c = monthly.Monthly_Actual_Revenue__c;
                    yearlyRollupRecord.Yearly_Forecasted_Revenue__c = monthly.Monthly_Forecasted_Revenue__c;
                    yearlyRollupRecord.Yearly_Forecasted_Revenue_Weighted__c = monthly.Monthly_Forecasted_Revenue_Weighted__c;
                    if(isMultiCurrencyEnabled)
                        yearlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Yearly_Revenue_Rollups__c'))
                        yearlyRollupsFY.add(yearlyRollupRecord);
                    
                    listOfYearlyIDs.remove(0);
                } else {
                    Yearly_Revenue_Rollups__c yearlyRollupRecord = new Yearly_Revenue_Rollups__c();
                    
                    yearlyRollupRecord.Name = monthly.Name;
                    if(Utility.checkFieldPermission(mapfieldYearlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                        yearlyRollupRecord.Opportunity__c = oppId;
                    yearlyRollupRecord.Year__c = monthly.Year__c;
                    yearlyRollupRecord.Yearly_Revenue_Date__c = monthly.Monthly_Revenue_Date__c; 
                    yearlyRollupRecord.Yearly_Actual_Revenue__c = monthly.Monthly_Actual_Revenue__c;
                    yearlyRollupRecord.Yearly_Forecasted_Revenue__c = monthly.Monthly_Forecasted_Revenue__c;
                    yearlyRollupRecord.Yearly_Forecasted_Revenue_Weighted__c = monthly.Monthly_Forecasted_Revenue_Weighted__c;
                    if(isMultiCurrencyEnabled)
                        yearlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Yearly_Revenue_Rollups__c'))
                        yearlyRollupsFY.add(yearlyRollupRecord);
                }
            }
            listYearlyToBeDeleted.addAll(listOfYearlyIDs);
        }
        
        if(listYearlyToBeDeleted.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'Yearly_Revenue_Rollups__c')))
            delete listYearlyToBeDeleted;
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Yearly_Revenue_Rollups__c')){
            if(yearlyRollupsFY.size() > 0)
                upsert yearlyRollupsFY;
        }
        
        if(isMultiCurrencyEnabled) {
            
            String Name;
            Id oppValue;
            String yearValue;
            Date dateValue;
            String yearlyActualValue; 
            String yearlyForecastedValue;
            String yearlyForecastedWeightedvalue;
           
            for(Yearly_Revenue_Rollups__c yR : yearlyRollupsFY) {
                Name = yR.Name;
                oppValue = yR.Opportunity__c;
                yearValue = yR.Year__c;
                dateValue = yR.Yearly_Revenue_Date__c;
               
                if(yR.Yearly_Actual_Revenue__c != null)
                    yearlyActualValue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), yR.Yearly_Actual_Revenue__c);
                
                if(yR.Yearly_Forecasted_Revenue__c != null)
                    yearlyForecastedValue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), yR.Yearly_Forecasted_Revenue__c);
                
                if(yR.Yearly_Forecasted_Revenue_Weighted__c != null)
                    yearlyForecastedWeightedvalue = utl.calculateAmountInCurrency(String.valueOf(oppty.get('CurrencyIsoCode')), yR.Yearly_Forecasted_Revenue_Weighted__c);
                
                listOfYearlyWrapper.add(new yearlyWrapper(yearValue, dateValue, yearlyActualValue, yearlyForecastedValue, yearlyForecastedWeightedvalue));
            }      
        }
        
        if(yearlyRollupsFY.size() > 0) {
            for(Yearly_Revenue_Rollups__c yR : yearlyRollupsFY) {
                if(!mapofOppIDWithYearlyIdAndString.containsKey(yR.Opportunity__c)) {
                    mapofOppIDWithYearlyIdAndString.put(yR.Opportunity__c, new Map<String, Id>());
                    if(!mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).containsKey(yR.Year__c))
                        mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).put(yR.Year__c, yR.id);
                }
                else {
                    mapofOppIDWithYearlyIdAndString.get(yR.Opportunity__c).put(yR.Year__c, yR.id);
                }
            }
        }
        
        if(mapofOppIDWithYearlyIdAndString.size() > 0)
            return mapofOppIDWithYearlyIdAndString;
        else 
            return null;
    }
    
    /**
    *  @Description    :    This method is used to show updated monthly records according to fiscal year
    *
    *  @args           :	Map<Id, Map<String,List<Monthly_Revenue_Rollups__c>>>, Map<Id, Map<String, Id>> 	    
    *
    *  @return Type    :    void
    **/
    public void showUpdatedMonthlyRecords(Map<Id, Map<String,List<Monthly_Revenue_Rollups__c>>> mapWithOppIdWithYearWithMonthlyRevenueFY, Map<Id, Map<String, Id>> mapofOppIDWithYearlyIdAndStringFY, Map<Id, Set<Monthly_Revenue_Rollups__c>> mapOfIdWithMonthlyRollup) {
        List<Monthly_Revenue_Rollups__c> listOfMonthlyRollupsFY = new List<Monthly_Revenue_Rollups__c>();
        listUpdateOfMonthly = new List<Monthly_Revenue_Rollups__c>();
        
        for(Id oppId : mapWithOppIdWithYearWithMonthlyRevenueFY.Keyset()) {
            for(Map<String,List<Monthly_Revenue_Rollups__c>> mapOfCombinedYears : mapWithOppIdWithYearWithMonthlyRevenueFY.values()) {
                for(String combinedYears : mapOfCombinedYears.keyset()) {
                    for(Monthly_Revenue_Rollups__c monthly : mapOfCombinedYears.get(combinedYears)) {
                        if(mapofOppIDWithYearlyIdAndStringFY.containsKey(oppId)) {
                            
                            Monthly_Revenue_Rollups__c monthlyRollupRecord = new Monthly_Revenue_Rollups__c(Id = monthly.Id,
                                                                                                            Monthly_Actual_Revenue__c = null,
                                                                                                            Monthly_Forecasted_Revenue__c = 0,
                                                                                                            Monthly_Forecasted_Revenue_Weighted__c = 0);
                            
                            monthlyRollupRecord.Name = monthly.Month__c + '-' + monthly.Year__c;
                            if(Utility.checkFieldPermission(mapfieldMonthlyResult,'Opportunity__c',Constants.PERMISSION_UPSERT))
                                monthlyRollupRecord.Opportunity__c = oppId;
                            monthlyRollupRecord.Year__c = monthly.Year__c;
                            monthlyRollupRecord.Month__c = monthly.Month__c;
                            monthlyRollupRecord.Monthly_Revenue_Date__c = monthly.Monthly_Revenue_Date__c;
                            monthlyRollupRecord.Yearly_Revenue_Rollup__c = mapofOppIDWithYearlyIdAndStringFY.get(oppId).get(combinedYears.substringAfter('-'));
                            monthlyRollupRecord.Monthly_Actual_Revenue__c = monthly.Monthly_Actual_Revenue__c;
                            monthlyRollupRecord.Monthly_Forecasted_Revenue__c = monthly.Monthly_Forecasted_Revenue__c;
                            monthlyRollupRecord.Monthly_Forecasted_Revenue_Weighted__c = monthly.Monthly_Forecasted_Revenue_Weighted__c;
                            if(isMultiCurrencyEnabled)
                                monthlyRollupRecord.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                            
                            listOfMonthlyRollupsFY.add(monthlyRollupRecord);
                        }
                        
                    }
                }
            }
        }
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Monthly_Revenue_Rollups__c')){
            if(listOfMonthlyRollupsFY.size() > 0)
                upsert listOfMonthlyRollupsFY;
        }
        
        if(isMultiCurrencyEnabled) {
            for(Monthly_Revenue_Rollups__c monthlyAccordingToCurrency : listOfMonthlyRollupsFY) {
                
                Monthly_Revenue_Rollups__c currencyMonthly = new Monthly_Revenue_Rollups__c();
                
                currencyMonthly.Id = monthlyAccordingToCurrency.Id;
                currencyMonthly.Name = monthlyAccordingToCurrency.Name;
                currencyMonthly.Opportunity__c = monthlyAccordingToCurrency.Opportunity__c;
                currencyMonthly.Year__c = monthlyAccordingToCurrency.Year__c;
                currencyMonthly.Month__c = monthlyAccordingToCurrency.Month__c;
                currencyMonthly.Monthly_Revenue_Date__c = monthlyAccordingToCurrency.Monthly_Revenue_Date__c;
                currencyMonthly.Yearly_Revenue_Rollup__c = monthlyAccordingToCurrency.Yearly_Revenue_Rollup__c;
                currencyMonthly.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                
                if(monthlyAccordingToCurrency.Monthly_Actual_Revenue__c != null)
                    currencyMonthly.Monthly_Actual_Revenue__c = monthlyAccordingToCurrency.Monthly_Actual_Revenue__c;
                
                if(monthlyAccordingToCurrency.Monthly_Forecasted_Revenue__c != null)
                    currencyMonthly.Monthly_Forecasted_Revenue__c = monthlyAccordingToCurrency.Monthly_Forecasted_Revenue__c;
                
                if(monthlyAccordingToCurrency.Monthly_Forecasted_Revenue_Weighted__c != null)
                    currencyMonthly.Monthly_Forecasted_Revenue_Weighted__c = monthlyAccordingToCurrency.Monthly_Forecasted_Revenue_Weighted__c;
                
                listUpdateOfMonthly.add(currencyMonthly);
                
            }
        }
        
        mapOfYearlyIdWithMonthlyRollups = new Map<String, List<Monthly_Revenue_Rollups__c>>();
        theListOfYears = new List<String>();
        for(Yearly_Revenue_Rollups__c yearly :[SELECT id, Name, (SELECT id, Name, Month__c, Year__c, Monthly_Revenue_Date__c, Opportunity__c, Yearly_Revenue_Rollup__c, 
                                                                 Monthly_Actual_Revenue__c, Monthly_Forecasted_Revenue__c, Monthly_Forecasted_Revenue_Weighted__c, Yearly_Revenue_Rollup__r.Name
                                                                 FROM Monthly_Revenue_Rollups__r
                                                                 WHERE Opportunity__c =: oppty.Id
                                                                 ORDER By Monthly_Revenue_Date__c ASC)
                                               FROM Yearly_Revenue_Rollups__c WHERE Opportunity__c =: oppty.Id ORDER By Year__c ASC]) 
        {
            for(Monthly_Revenue_Rollups__c monthly : yearly.Monthly_Revenue_Rollups__r) {
                if(!mapOfYearlyIdWithMonthlyRollups.containsKey(monthly.Yearly_Revenue_Rollup__r.Name))
                    mapOfYearlyIdWithMonthlyRollups.put(monthly.Yearly_Revenue_Rollup__r.Name, new List<Monthly_Revenue_Rollups__c>());
                mapOfYearlyIdWithMonthlyRollups.get(monthly.Yearly_Revenue_Rollup__r.Name).add(monthly);
            }  
        }
        if(mapOfYearlyIdWithMonthlyRollups.size() > 0) {
            for(String str : mapOfYearlyIdWithMonthlyRollups.keySet()) {
                theListOfYears.add(str);
            }
        }     
    }
    
    /**
    *  Description     :   wrapper to hold CurrentFiscalYearMonthlyRecords 
    **/
    public class CurrentFiscalYearMonthlyRecords {
        //Properties
        public String scheduleRecRev { get; set; }
        public String scheduleRecRevWei { get; set; }
        public String schYear { get; set; } 
        public string month { get; set; }
        public Date scheduleDate { get; set; }
        
        //Constructor
        public CurrentFiscalYearMonthlyRecords(String scheduleRecRev, String scheduleRecRevWei, String schYear, String month, Date scheduleDate) 
        {
            //Assigning in wrapper valiable
            this.scheduleRecRev = scheduleRecRev;
            this.scheduleRecRevWei = scheduleRecRevWei;
            this.schYear = schYear;
            this.month = month;
            this.scheduleDate = scheduleDate;
        }
    }
    /**
    *  Description     :   wrapper to hold fiscalYearMonthlyRecordsWithSingleCurrency 
    **/
    public class fiscalYearMonthlyRecordsWithSingleCurrency {
        //Properties
        public Decimal totalSchRecRev { get; set; }
        public Decimal totalSchRecRevWei { get; set; }
        public String schYear { get; set; } 
        public string month { get; set; }
        public Date scheduleDate { get; set; }
        
        //Constructor
        public fiscalYearMonthlyRecordsWithSingleCurrency(Decimal totalSchRecRev, Decimal totalSchRecRevWei, String schYear, String month, Date scheduleDate) 
        {
            //Assigning in wrapper valiable
            this.totalSchRecRev = totalSchRecRev;
            this.totalSchRecRevWei = totalSchRecRevWei;
            this.schYear = schYear;
            this.month = month;
            this.scheduleDate = scheduleDate;
        }
    }
    
    /**
    *  Description     :   wrapper to hold yearly wrapper 
    **/
    public class yearlyWrapper {
        //Properties
        public String yearValue { get; set; }
        public Date dateValue { get; set; }
        public String yearlyActualValue { get; set; }
        public String yearlyForecastedValue { get; set; } 
        public string yearlyForecastedWeightedvalue { get; set; }
        
        //Constructor
        public yearlyWrapper(String yearValue, Date dateValue, String yearlyActualValue, 
                             String yearlyForecastedValue, String yearlyForecastedWeightedvalue) 
        {
            //Assigning in wrapper valiable
            this.yearValue = yearValue;
            this.dateValue = dateValue;
            this.yearlyActualValue = yearlyActualValue;
            this.yearlyForecastedValue = yearlyForecastedValue;
            this.yearlyForecastedWeightedvalue = yearlyForecastedWeightedvalue;
        }
    }
    
    /**
    *  Description     :   wrapper to hold monthly wrapper 
    **/
    public class monthlyWrapper {
        //Properties
        public Decimal monthValue { get; set; }
        public String yearValue { get; set; }
        public Date dateValue { get; set; }
        public String monthlyActualValue { get; set; }
        public String monthlyForecastedValue { get; set; } 
        public string monthlyForecastedWeightedvalue { get; set; }
        
        //Constructor
        public monthlyWrapper(Decimal monthValue, String yearValue, Date dateValue, String monthlyActualValue, 
                              String monthlyForecastedValue, String monthlyForecastedWeightedvalue) 
        {
            //Assigning in wrapper valiable
            this.monthValue = monthValue;
            this.yearValue = yearValue;
            this.dateValue = dateValue;
            this.monthlyActualValue = monthlyActualValue;
            this.monthlyForecastedValue = monthlyForecastedValue;
            this.monthlyForecastedWeightedvalue = monthlyForecastedWeightedvalue;
        }
    }
}