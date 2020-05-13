public with sharing class RevRecScheduleList { 
	
    private String opportunityId;
    public Decimal oppTotalAmountWei{get;set;}
    private String lineItemId;
    private Opportunity theOpportunity;
    private OpportunityLineItem lineItem;
    private RevRecRules__c theRule;
    
    public List<RevRecProductRule__c> overrideRule{get;set;}
    
    //Code added - 02/18/2015 - As per Advance currency managmnet issue
    public Boolean isMultiCurrencyEnabled{get;set;}
    Public String oppLineTotalOpportunity{get;set;}
    Public String revRecOppTotalRecognized{get;set;} 
    Public String revRecOppTotalDeferred{get;set;}
    Public String revRecOppTotalResidual{get;set;}  
    Public String oppLineTotalOpportunityWei{get;set;}
    Public String revRecOppTotalRecognizedWei{get;set;} 
    Public String revRecOppTotalDeferredWei{get;set;}
    Public String revRecOppTotalResidualWei{get;set;}  
    public List<revRecScheduleWrapper> revRecScheduleList {get;set;}
    List<RevRecOpportunityLineItemSchedule__c> schedules = new List<RevRecOpportunityLineItemSchedule__c>();
    String scheduleDeferred ;
    String scheduleRecognized;
    String scheduleDeferredWei ;
    String scheduleRecognizedWei;
    String scheduleForecastedWei;
    public static Opportunity opp {get;set;}
    public String currecyCode {get;set;}
    public static String currencyFormate {get;set;}
	public static RevRecAppSetting__c theSetting;
	public Boolean setPastSchDeferredWith0 {get;set;}
    
    //Initilize utility class
    Utility utl;
    
    //Code added -As per Blended Revenue Recognition functionality
    public List<String> listCategoryNames {get;set;}
     
    //String to hold user's currency
    String userCurrencyIsoCode = userInfo.getDefaultCurrency();
   
    //Added on 06/27/2018 - Enhancement to show charts on the page for revenues
    //List to hold chart data
    public static List<BarChartDataWrapper> barChartData {get; set;}
    public static List<BarChartDataWrapperBR> barChartDataBR {get; set;}
    
    //Boolean variables to show visibility of charts
    public Boolean isShowRevenueWeiChart {get; set;}
	public Boolean isShowForecastedChart {get; set;}
	public Boolean isShowPastLegends {get;set;}
	public Boolean isShowFutureLegends {get; set;}
    
    public RevRecScheduleList () { 
        
        //Checking if currency enabled for the org
		isMultiCurrencyEnabled =  UserInfo.isMultiCurrencyOrganization();
        listCategoryNames = new List<String>();

        //SET Today's date 
        opp = new Opportunity();
        opp.CloseDate = Date.Today();
        
        setPastSchDeferredWith0 = false;
        
        //Initialization
        isShowRevenueWeiChart = false;
        isShowPastLegends = false;
        isShowFutureLegends = false;
        
        //Initilize list of wrapper
        revRecScheduleList = new List<revRecScheduleWrapper>();
        barChartData = new List<BarChartDataWrapper>();
        barChartDataBR = new List<BarChartDataWrapperBR>();
        
        //Calling init method
        init();  
    }
    
    public void init() {
    	
    	//Re-initialization 
        setPastSchDeferredWith0 = false;
        isShowRevenueWeiChart = false;
		isShowForecastedChart = false;
        currencyFormate = userInfo.getDefaultCurrency();
        opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        lineItemId =  ApexPages.currentPage().getParameters().get('opportunityLineItemId');
                           
        List<RevRecAppSetting__c> theSettingList = [Select Chart_Pref__c FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
              
        if (theSettingList.Size() > 0 ) {
            theSetting = theSettingList[0];
            if(theSetting.Chart_Pref__c == '1')
            	setPastSchDeferredWith0 = false;
            else if(theSetting.Chart_Pref__c == '2')
                setPastSchDeferredWith0 = true;
        }  
                                   
        //Code added - 02/18/2015 - As per Advance currency management issue
        transient String query = '';
        if(!isMultiCurrencyEnabled)
            query += 'SELECT Id, name, stageName, IsWon, IsClosed, CloseDate,Probability FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
        else
            query += 'SELECT Id, name, CloseDate, StageName, CurrencyIsoCode , IsWon, IsClosed, Probability FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
        
        //Query
        transient Opportunity theOpportunity = Database.query(query);

		//Set flag to show visibility for revenue weighted chart
        if(theOpportunity.Probability < 100)
        	isShowRevenueWeiChart = true;
        	
   	 	//Initilize Ut
        utl = new Utility(theOpportunity);

        //Code added - 03/24/2015 - Add  "PricebookEntry.product2.RevRecRule__r.Recognition_Type__c" in query
        lineItem = 
            [SELECT Id, Name, OpportunityId, PricebookEntryId, Quantity, Description, UnitPrice,TotalPrice,RevRecRule__c,
                PricebookEntry.Name,PricebookEntry.product2.id, 
                RevRecRule__r.Name,RevRecRule__r.Recognition_Type__c ,
                PricebookEntry.product2.RevRecRule__r.Id, 
                PricebookEntry.product2.RevRecRule__r.name,
                PricebookEntry.product2.RevRecRule__r.Recognition_Type__c,
                RevRecOpportunityLineItem__r.Id,
                RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
                RevRecOpportunityLineItem__r.TotalRev__c,
                RevRecOpportunityLineItem__r.DeferredRev__c,
                RevRecOpportunityLineItem__r.RecognizedRev__c,
                RevRecOpportunityLineItem__r.CalculatedAt__c, 
                RevRecOpportunityLineItem__r.ResidualAmount__c,
                RevRecOpportunityLineItem__r.ProductName__c,
             	RevRecOpportunityLineItem__r.ResAmtWei__c,
             	RevRecOpportunityLineItem__r.DefReWei__c,
                RevRecOpportunityLineItem__r.RecRevWei__c
           FROM OpportunityLineItem Where Id = :lineItemId LIMIT 1];
          
        if(!isMultiCurrencyEnabled && lineItem.TotalPrice != null)
            oppTotalAmountWei = (lineItem.TotalPrice * theOpportunity.Probability)/100;

         //Checking for multi currency enable
        //Code added - 02/18/2015 - As per Advance currency managemnet issue
        if(isMultiCurrencyEnabled) {
            
            currecyCode = String.valueOf(theOpportunity.get('CurrencyIsoCode'));
            
            //Checking for null
            if(lineItem.TotalPrice != null)
                oppLineTotalOpportunity =  utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.TotalPrice);
            else
                oppLineTotalOpportunity = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(lineItem.TotalPrice != null)
                oppLineTotalOpportunityWei =  utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), (lineItem.TotalPrice * theOpportunity.Probability)/100);
            else
                oppLineTotalOpportunityWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null 
            if(lineItem.RevRecOpportunityLineItem__r.RecognizedRev__c != null)
                revRecOppTotalRecognized = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.RecognizedRev__c);
            else
                revRecOppTotalRecognized = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null 
            if(lineItem.RevRecOpportunityLineItem__r.RecRevWei__c != null)
                revRecOppTotalRecognizedWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.RecRevWei__c );
            else
                revRecOppTotalRecognizedWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //checking for null
            if(lineItem.RevRecOpportunityLineItem__r.DeferredRev__c != null)
                revRecOppTotalDeferred =   utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.DeferredRev__c);
            else
                revRecOppTotalDeferred = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //checking for null
            if(lineItem.RevRecOpportunityLineItem__r.DefReWei__c != null)
                revRecOppTotalDeferredWei =   utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.DefReWei__c);
            else
                revRecOppTotalDeferredWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(lineItem.RevRecOpportunityLineItem__r.ResidualAmount__c != null)
                revRecOppTotalResidual =   utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.ResidualAmount__c);    
            else
                revRecOppTotalResidual = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(lineItem.RevRecOpportunityLineItem__r.ResAmtWei__c != null)
                revRecOppTotalResidualWei =   utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.ResAmtWei__c);
            else
                revRecOppTotalResidualWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
        }    
        
        if (lineItem.RevRecRule__c != null)   
            theRule = lineItem.RevRecRule__r ; 
         
        if (theRule == null) {
            
            List<RevRecRules__c> ruleList = [select Id, name, Active__c, Default_Rule__c, Description__c, Divide_By__c, initial_amount__c, initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, Period_or_Exact_Days__c, Recognition_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Revenue_Recognition_End_Date__c,  Revenue_Recognition_Start_Date__c from RevRecRules__c where Default_Rule__c = true and Active__c = true];
            
            if (ruleList.Size() == 0) 
                theRule = [select Id, name, Active__c, Default_Rule__c, Description__c, Divide_By__c, initial_amount__c, initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, Period_or_Exact_Days__c, Recognition_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Revenue_Recognition_End_Date__c,  Revenue_Recognition_Start_Date__c from RevRecRules__c where Active__c = true limit 1][0];
            else 
                theRule =  ruleList[0];
        }
        overrideRule = [Select Id, name, Recognition_Type__c From RevRecProductRule__c Where RevRecOpportunityLineItem__c =: lineItem.RevRecOpportunityLineItem__c LIMIT 1];

        //Chceking for multi currency enabled
        if(isMultiCurrencyEnabled) {
            
            Decimal seq = 0;
            Date dt ;
            String month = '';
            Set<String> catNames = new Set<String>(); 
            Map<String, List<String>> mapCatSchAmtWithCatSchAmtWei = new Map<String, List<String>>();
            List<Decimal> listCatSchAmountD = new List<Decimal>();
            List<Decimal> listCatSchAmountDWei = new List<Decimal>();
            String totalRecognizeAmount;
            String totalRecognizeAmountWei;
            Decimal totalRecognizedAmount = 0.00;
            Decimal totalRecognizedAmountWei = 0.00;
            String totalDeferred;
            String totalDeferredWei;
            Decimal totalDeferredAmount = 0.00;
            Decimal totalDeferredAmountWei = 0.00;
            Decimal recognizedCumulativeRev = 0.00;
            String totalForecastedAmount;
            Decimal forecastedCumulativeRev = 0.00;
            Decimal forecastedCumulativeWei = 0.00;
            
            //Code added - 02/20/2015 - As per Advance currency management issue 
            for(RevRecOpportunityLineItemSchedule__c sch : [select Date__c, DeferredRev__c, RecognizedRev__c, Month__c, Sequence__c, DefReWei__c, RecRevWei__c,
                                                            (Select Amount1__c, Amt_Wei__c, Category_Name__c From RevRecScheduleCategorys__r ORDER BY Category_Name__c),
                                                            ForecastedRev__c, ForeRevWei__c
                                                            from RevRecOpportunityLineItemSchedule__c 
                                                            where OpportunityLineItemId__c = :lineItemId order by Date__c]) {

                //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
	            //If true the do this 
	            if(isMultiCurrencyEnabled) {
	            	
	                //Checking for null
	                if(sch.DeferredRev__c != null)
	                    scheduleDeferred = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.DeferredRev__c);
	                else
	                    scheduleDeferred = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
	                
	                //Checking for null
	                if(sch.RecognizedRev__c != null)
	                    scheduleRecognized = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.RecognizedRev__c);
	                else
	                    scheduleRecognized = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';

                    //Checking for null
	                if(sch.DefReWei__c != null)
	                    scheduleDeferredWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.DefReWei__c);
	                else
	                    scheduleDeferredWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
	                
	                //Checking for null
	                if(sch.RecRevWei__c != null)
	                    scheduleRecognizedWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.RecRevWei__c);
	                else
	                    scheduleRecognizedWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';	                    
                    
                    //Checking for null
	                if(sch.ForeRevWei__c != null)
	                    scheduleForecastedWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.ForeRevWei__c);
	                else
	                    scheduleForecastedWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';	                    
                }
	            
                if(sch.Sequence__c != null)
                    seq = sch.Sequence__c;      
                
                if(sch.Date__c != null)
                    dt = sch.Date__c;
                
                if(sch.Month__c != null)
                    month = sch.Month__c;
                   
             	mapCatSchAmtWithCatSchAmtWei = new Map<String, List<String>>();

				if(sch.RevRecScheduleCategorys__r.size() > 0) {
                            
                    //Loop over schedule Category
                    for(RevRecScheduleCategory__c schC : sch.RevRecScheduleCategorys__r) {
                        
                        catNames.add(schC.Category_Name__c);
                        
                        //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                        if(isMultiCurrencyEnabled) {
                            List<String> amts = new List<String>();
                            if(schC.Amount1__c != null)
                                amts.add(utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), schC.Amount1__c));
                            else
                                amts.add(theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )');
                            if(schC.Amt_Wei__c != null)
                                amts.add(utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), schC.Amt_Wei__c));
                            else
                                amts.add(theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )');
                            mapCatSchAmtWithCatSchAmtWei.put(schC.Category_Name__c, amts);
                        }
                    }
                }
				
				//-Id condition added to restrict schedule recognize and deferred amount to be same as at overriden screen
				if(sch.RecognizedRev__c != null)  //Added on 03/05/2018 for newly generated issue on Issue#4
	            	totalRecognizedAmount += sch.RecognizedRev__c;
				if(sch.RecRevWei__c != null)   //Added on 03/05/2018 for newly generated issue on Issue#4
					totalRecognizedAmountWei += sch.RecRevWei__c ;
                if(sch.ForecastedRev__c != null)
                    forecastedCumulativeRev += sch.ForecastedRev__c;
                if(sch.ForeRevWei__c != null)
            		forecastedCumulativeWei += sch.ForeRevWei__c;
            			
                //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                if(isMultiCurrencyEnabled) {
                	totalRecognizeAmount = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), totalRecognizedAmount);
                	totalRecognizeAmountWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), totalRecognizedAmountWei);
                    totalForecastedAmount = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), forecastedCumulativeRev);
                }
                totalDeferredAmount = Math.abs(lineItem.TotalPrice - totalRecognizedAmount);
				totalDeferredAmountWei = ((Math.abs(lineItem.TotalPrice - totalRecognizedAmount)) * theOpportunity.Probability)/100;                                                                 

                //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                if(isMultiCurrencyEnabled) {
                	totalDeferred = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), totalDeferredAmount);
                	totalDeferredWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), totalDeferredAmountWei);
                } 
                
            	if(sch.ForeRevWei__c == null)
            		sch.ForeRevWei__c = 0.00;
                 
                //Populate wrappper
                if(sch.RevRecScheduleCategorys__r.size() > 0)
                    revRecScheduleList.add(new revRecScheduleWrapper(seq, scheduleDeferred, scheduleRecognized, scheduleDeferredWei, scheduleRecognizedWei, dt, month, sch.RevRecScheduleCategorys__r,
                                                                     mapCatSchAmtWithCatSchAmtWei, totalRecognizeAmount, totalRecognizeAmountWei, totalRecognizedAmount, totalRecognizedAmountWei, 
                                                                     totalDeferredAmountWei,sch, totalDeferred, totalDeferredWei, totalDeferredAmount, listCatSchAmountD, 
                                                                     listCatSchAmountDWei, forecastedCumulativeRev, totalForecastedAmount, scheduleForecastedWei)); 
				else {
                    revRecScheduleList.add(new revRecScheduleWrapper(seq, scheduleDeferred, scheduleRecognized, scheduleDeferredWei, scheduleRecognizedWei, dt, month, Null, 
                                                                     Null, totalRecognizeAmount, totalRecognizeAmountWei, totalRecognizedAmount, totalRecognizedAmount, 
                                                                     totalDeferredAmountWei, sch, totalDeferred, totalDeferredWei, totalDeferredAmount, Null, 
                                                                     null, forecastedCumulativeRev, totalForecastedAmount, scheduleForecastedWei)); 
                }
                
                //Check for Blended Rule, and populate chart list 
                if((overrideRule.size() > 0 && overrideRule[0].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) || theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)
					barChartDataBR.add(new BarChartDataWrapperBR(null, null, null, sch.RecognizedRev__c, totalDeferredAmount, sch.RecRevWei__c, totalDeferredAmountWei, sch.ForecastedRev__c, 0, sch.ForeRevWei__c, Date.valueOf(dt).format(), dt, totalRecognizedAmount, totalRecognizedAmountWei, forecastedCumulativeRev, forecastedCumulativeWei));
            }

            //Add set into list
            if(catNames.size() > 0)
                listCategoryNames.addAll(catNames);
            mapCatSchAmtWithCatSchAmtWei = new Map<String, List<String>>();
        }else {
            
            Decimal seq = 0;
            Date dt ;
            String month = '';
            
            //Code Added as per Blended revenue functionality
            Set<String> catNames = new Set<String>(); 
            Map<String, List<String>> mapCatSchAmtWithCatSchAmtWei = new Map<String, List<String>>();
            List<Decimal> listCatSchAmountD = new List<Decimal>();
            List<Decimal> listCatSchAmountDWei = new List<Decimal>();
            
            String totalRecognizeAmount;
            String totalRecognizeAmountWei;
            Decimal totalRecognizedAmount = 0.00;
            Decimal totalRecognizedAmountWei = 0.00;
            String totalDeferred;
            String totalDeferredWei;
            Decimal totalDeferredAmount = 0.00;
            Decimal totalDeferredAmountWei = 0.00;
            String totalForecastedAmount;
            Decimal forecastedCumulativeRev = 0.00;
            Decimal forecastedCumulativeWei = 0.00;
            
            //Code added - 02/20/2015 - As per Advance currency management issue 
            for(RevRecOpportunityLineItemSchedule__c sch : [select Date__c, DeferredRev__c, RecognizedRev__c, Month__c, Sequence__c, RecRevWei__c, DefReWei__c,
                                                            (Select Amount1__c, Amt_Wei__c, Category_Name__c From RevRecScheduleCategorys__r ORDER BY Category_Name__c),
                                                            ForecastedRev__c, ForeRevWei__c
                                                             from RevRecOpportunityLineItemSchedule__c 
                                                             where OpportunityLineItemId__c = :lineItemId order by Date__c]) {
                
                //Ininilize      
                listCatSchAmountDWei = new List<Decimal>();
                listCatSchAmountD = new List<Decimal>();
                mapCatSchAmtWithCatSchAmtWei = new Map<String, List<String>>();
                                                                 
                if(sch.RevRecScheduleCategorys__r.size() > 0) {
                    
                    ///Loop oveer schedule Category
                    for(RevRecScheduleCategory__c schC : sch.RevRecScheduleCategorys__r) {
                        catNames.add(schC.Category_Name__c);
                        listCatSchAmountD.add(schC.Amount1__c);
                        listCatSchAmountDWei.add(schC.Amt_Wei__c);
                    }
                }
                
                if(sch.Sequence__c != null)
                    seq = sch.Sequence__c;      
                
                if(sch.Date__c != null) 
                    dt = sch.Date__c;
                
                if(sch.Month__c != null)
                    month = sch.Month__c;
                
                                                                 
				if(sch.RecognizedRev__c != null)
	                totalRecognizedAmount += sch.RecognizedRev__c;
                totalDeferredAmount = Math.abs(lineItem.TotalPrice  - totalRecognizedAmount);
				
                if(sch.RecognizedRev__c != null)
                	totalRecognizedAmountWei += (sch.RecognizedRev__c * theOpportunity.Probability)/100;
                totalDeferredAmountWei = ((Math.abs(lineItem.TotalPrice  - totalRecognizedAmount)) * theOpportunity.Probability)/100;                                                                 
                
                //Check for null values
                if(sch.ForecastedRev__c == null)
                	sch.ForecastedRev__c = 0.00;
                forecastedCumulativeRev += sch.ForecastedRev__c;
                	
            	if(sch.ForeRevWei__c == null)
            		sch.ForeRevWei__c = 0.00;
                forecastedCumulativeWei = sch.ForeRevWei__c;
            	
                //Populate wrappper
                if(sch.RevRecScheduleCategorys__r.size() > 0)
                    revRecScheduleList.add(new revRecScheduleWrapper(seq, scheduleDeferred, scheduleRecognized, scheduleDeferredWei, scheduleRecognizedWei, dt, month, sch.RevRecScheduleCategorys__r,
                                                                     mapCatSchAmtWithCatSchAmtWei, totalRecognizeAmount, totalRecognizeAmountWei, totalRecognizedAmount, 
                                                                     totalRecognizedAmountWei, totalDeferredAmountWei, sch, totalDeferred, totalDeferredWei, totalDeferredAmount, listCatSchAmountD, 
                                                                     listCatSchAmountDWei, forecastedCumulativeRev, totalForecastedAmount, scheduleForecastedWei)); 
                else
                    revRecScheduleList.add(new revRecScheduleWrapper(seq, scheduleDeferred, scheduleRecognized, scheduleDeferredWei, scheduleRecognizedWei, dt, month, Null, 
                                                                     Null, totalRecognizeAmount, totalRecognizeAmountWei, totalRecognizedAmount,
                                                                     totalRecognizedAmountWei, totalDeferredAmountWei, sch, totalDeferred, totalDeferredWei, totalDeferredAmount, Null, 
                                                                     Null, forecastedCumulativeRev, totalForecastedAmount, scheduleForecastedWei)); 
            	
            	//Check for blended rule and populate chart list
            	if((overrideRule.size() > 0 && overrideRule[0].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) || theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)
            		barChartDataBR.add(new BarChartDataWrapperBR(null, null, null, sch.RecognizedRev__c, totalDeferredAmount, sch.RecRevWei__c, totalDeferredAmountWei, sch.ForecastedRev__c, 0, sch.ForeRevWei__c, Date.valueOf(dt).format(), dt, totalRecognizedAmount, totalRecognizedAmountWei, forecastedCumulativeRev, forecastedCumulativeWei));
            }
            
            //Add set into list
            if(catNames.size() > 0)
                listCategoryNames.addAll(catNames);
            listCatSchAmountD = new List<Decimal>();
            listCatSchAmountDWei = new List<Decimal>();
        }
        
        Decimal recognizedCumulativeRev = 0.00;
        Decimal recogCumulativeRevWei = 0.00;
        Decimal forecastedCumulativeRev = 0.00;
        Decimal forecastedCumulativeWei = 0.00;
        
        //Check if rule type is not blended rule
        if((overrideRule.size() > 0 && overrideRule[0].Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) || theRule.Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
        	
        	//Query through schedules
	        schedules = (List<RevRecOpportunityLineItemSchedule__c>) setCon.getRecords();
	        
	        //Loop over schedules to populate data in the wrapper list
	        for(RevRecOpportunityLineItemSchedule__c sch : schedules) {
                
                if(sch.ForecastedRev__c == null)
                	sch.ForecastedRev__c = 0.00;
            	
            	if(sch.ForeRevWei__c == null)
            		sch.ForeRevWei__c = 0.00;
            		
                //Assign cumulative recognized revenue
                recognizedCumulativeRev += sch.RecognizedRev__c;
                recogCumulativeRevWei += sch.RecRevWei__c;
                if(sch.ForecastedRev__c != null)
                	forecastedCumulativeRev += sch.ForecastedRev__c;
                
                if(sch.ForeRevWei__c != null) 
                    forecastedCumulativeWei += sch.ForeRevWei__c;
	            barChartData.add(new BarChartDataWrapper(null, null, null, sch.RecognizedRev__c, sch.DeferredRev__c, sch.RecRevWei__c, sch.DefReWei__c, 
                                                         Date.valueOf(sch.Date__c).format(), sch.ForecastedRev__c, 0, sch.ForeRevWei__c, sch.Date__c, 
                                                         recognizedCumulativeRev, recogCumulativeRevWei, forecastedCumulativeRev, forecastedCumulativeWei));
	        }
        }
        
        //Check for list size, and set visibility for forecasted revenue chart
    	if(barChartData.size() > 0) {

    		//Loop over bar chart data
			for(BarChartDataWrapper bar : barChartData) {
				
				//Set visibility for forecasted Revenue chart
    			if(bar.Forecasted > 0) {
    				isShowForecastedChart = true;
        			break;
    			}
			}
			for(BarChartDataWrapper bar : barChartData) {
				
		       	if(bar.schDate < Date.today()) 
		       		isShowPastLegends = true;
	       		else
	       			isShowFutureLegends = true;
       			if(isShowPastLegends == true && isShowFutureLegends == true)
       				break;
			}
    	} else if(barChartDataBR.size() > 0) {
                	
        	//Loop over bar chart data
			for(BarChartDataWrapperBR bar : barChartDataBR) {
				
				//Set visibility for forecasted Revenue chart
    			if(bar.Forecasted > 0) {
    				isShowForecastedChart = true;
        			break;
    			}
			}
			for(BarChartDataWrapperBR bar : barChartDataBR) {
				if(bar.schDate < Date.today()) 
		       		isShowPastLegends = true;
	       		else
	       			isShowFutureLegends = true;
       			if(isShowPastLegends == true && isShowFutureLegends == true)
       				break;
			}
    	}
    }
    
    public ApexPages.StandardSetController setCon {
        get {
            if (setCon == null) {
                
                //Codde modified -  Added inline query to get related category for schedule
                List<RevRecOpportunityLineItemSchedule__c> theList = [select Date__c, DeferredRev__c, RecognizedRev__c, Month__c, Sequence__c, DefReWei__c, RecRevWei__c,
                                    (Select Amount1__c, Amt_Wei__c, Category_Name__c From RevRecScheduleCategorys__r ORDER BY Name), ForecastedRev__c, ForeRevWei__c
                                     from RevRecOpportunityLineItemSchedule__c 
                                     where OpportunityLineItemId__c = :lineItemId order by Date__c];
                
                setCon = new ApexPages.StandardSetController(theList);
                setCon.setPagesize(2000);
             }
             return setCon;   
        }
        set;
    }
    
    public List<RevRecLineItemScheduleWrapper> getRevRecSchedules() {
        
        //Declarations
        Decimal cumulativeRecRev = 0.00;
        Decimal cumulativeRecRevWei = 0.00;
        Decimal cumulativeForecasted = 0.00;
        
        List<RevRecLineItemScheduleWrapper> revRecLineItemSchedules = new List<RevRecLineItemScheduleWrapper>();
        
        //Codde modified -  Added inline query to get related category for schedule
        List<RevRecOpportunityLineItemSchedule__c> theList = [select Date__c, DeferredRev__c, RecognizedRev__c, Month__c, Sequence__c, DefReWei__c, RecRevWei__c,
                                                              (Select Amount1__c, Amt_Wei__c, Category_Name__c From RevRecScheduleCategorys__r ORDER BY Name), ForecastedRev__c, ForeRevWei__c
                                                              from RevRecOpportunityLineItemSchedule__c 
                                                              where OpportunityLineItemId__c = :lineItemId order by Date__c];
        
        //Loop over queried data
        for(RevRecOpportunityLineItemSchedule__c sch : theList) {
        	
        	if(sch.ForecastedRev__c == null)
                sch.ForecastedRev__c = 0.00;
            if(sch.ForeRevWei__c == null)
            	sch.ForeRevWei__c = 0.00;
            	      
        	if(sch.RecognizedRev__c != null)
	            cumulativeRecRev += sch.RecognizedRev__c;
        	if(sch.RecRevWei__c != null)
            	cumulativeRecRevWei += sch.RecRevWei__c;
        	if(sch.ForecastedRev__c != null)
            	cumulativeForecasted += sch.ForecastedRev__c;
            revRecLineItemSchedules.add(new RevRecLineItemScheduleWrapper(sch, cumulativeRecRev, cumulativeRecRevWei, cumulativeForecasted));
        }
        return revRecLineItemSchedules;
    }
    
    public OpportunityLineItemWrapper getLineItem() {
        OpportunityLineItemWrapper item = new OpportunityLineItemWrapper();
        item.LineItem = lineItem;
        item.RevRecLineItem = lineItem.RevRecOpportunityLineItem__r;
        return item;
    }
    
    //Code added - 02/20/2015 - wrapper class to hold schedule prroperties
    public class revRecScheduleWrapper {
        
        //Properties
        public Decimal sequence {get;set;}
        public string scheduleDeferred {get;set;}
        public string scheduleRecRev {get;set;}
        public string scheduleDeferredWei {get;set;}
        public string scheduleRecRevWei {get;set;}
        public Date schDate{get;set;}
        public RevRecOpportunityLineItemSchedule__c schDate1 {get;set;}
        public string month {get;set;}
        
        //code added - 06/25/2015 - As per blended revenue recogniton
        public List<RevRecScheduleCategory__c> revScheduleCategory {get;set;}
        public Map<String,List<String>> mapCatSchAmtWithCatSchAmtWei {get;set;}
        public List<Decimal> listCategoryAmountD {get;set;}
        public List<Decimal> listCategoryAmountDwei {get;set;}
        public String totalRecognized {get;set;}
        public String totalRecognizedWei {get;set;}
        public String totalDeferred{get;set;}
        public String totalDeferredWei{get;set;}
        public Decimal totalRecognizedWithNoMultiCurency {get;set;}
        public Decimal totalDeferredWithNoMultiCurrency{get;set;}
        public Decimal totalRecognizedWithNoMultiCurencyWei {get;set;}
        public Decimal totalDeferredWithNoMultiCurrencyWei{get;set;}
        public RevRecOpportunityLineItemSchedule__c scheduleWithoutMultiCurrency {get;set;}
        public String chartDate {get; set;}
        public Decimal totalForeAmount{get; set;}
        public String totalForecasted {get;set;}
        public string schForecastedWei {get;set;}
        
        //Constructer
        public revRecScheduleWrapper(Decimal sequence, string scheduleDeferred, string scheduleRecRev, string scheduleDeferredWei, string scheduleRecRevWei, Date schDate, 
                                     String month, List<RevRecScheduleCategory__c> revScheduleCategory,Map<String,List<String>> mapCatSchAmtWithCatSchAmtWei,
                                     String totalRecognized,String totalRecognizedWei, Decimal totalRecognizedWithNoMultiCurency, Decimal totalRecognizedWithNoMultiCurencyWei, 
                                     Decimal totalDeferredWithNoMultiCurrencyWei,RevRecOpportunityLineItemSchedule__c scheduleWithoutMultiCurrency,
                                     String totalDeferred, String totalDeferredWei, Decimal totalDeferredWithNoMultiCurrency, List<Decimal> listCategoryAmountD, 
                                     List<Decimal> listCategoryAmountDWei, Decimal totalForeAmount, String totalForecasted, String schForecastedWei) {
            
            this.sequence = sequence;
            this.scheduleDeferred = scheduleDeferred;
            this.scheduleRecRev = scheduleRecRev;
            this.scheduleDeferredWei = scheduleDeferredWei;
            this.scheduleRecRevWei = scheduleRecRevWei;
            this.schDate = schDate;
            this.schDate1  = new RevRecOpportunityLineItemSchedule__c();
            this.schDate1.OriginalDate__c = schDate;
            this.month = month; 
            
            //Code addded - As per blended revenue schedules
            this.revScheduleCategory = revScheduleCategory;
            this.mapCatSchAmtWithCatSchAmtWei = mapCatSchAmtWithCatSchAmtWei;
            this.listCategoryAmountD = listCategoryAmountD;
            this.listCategoryAmountDWei = listCategoryAmountDWei;                                         
            this.totalRecognized = totalRecognized;
            this.totalRecognizedWei = totalRecognizedWei;
            this.totalRecognizedWithNoMultiCurency = totalRecognizedWithNoMultiCurency;
            this.totalRecognizedWithNoMultiCurencyWei = totalRecognizedWithNoMultiCurencyWei;
            this.scheduleWithoutMultiCurrency = scheduleWithoutMultiCurrency;
            this.totalDeferred = totalDeferred;
			this.totalDeferredWei = totalDeferredWei;                                         
            this.totalDeferredWithNoMultiCurrency = totalDeferredWithNoMultiCurrency;
            this.totalDeferredWithNoMultiCurrencyWei = totalDeferredWithNoMultiCurrencyWei;
			this.totalForecasted = totalForecasted;
			this.schForecastedWei = schForecastedWei;
			this.totalForeAmount = totalForeAmount;
        } 
    }   
   
    public  RevRecRules__c getRule () {return theRule;} 

    public Opportunity getOpportunity() { return theOpportunity; }                   
    
    public PageReference cancel() { return new PageReference('/' + opportunityId) ;  } 
    
    public PageReference ExportToExcel() { 
        PageReference pr = Page.RevRecScheduleOutputAsExcel;
        pr.getParameters().put('opportunityLineItemId',lineItemId);
        pr.getParameters().put('opportunityId',opportunityId);
        return pr ;  
    }
     
 	/**
     *  @Description    :   This method is used to set colors in the wrapper list that hold chart data.
     *
     *  @args           :   void
     *
     *  @return Type    :   String
     **/
    public string getColors(){
    	
    	//Variable declaration
        string colorCodes = '';
        
        //Check for size
        if(barChartData.size() > 0) {
        	
        	//Loop over wrapper list and set colors to it
        	for(BarChartDataWrapper recData : barChartData)
	            colorCodes += recData.colorCode + ',' + recData.colorCodeZero + ',' + recData.colorCodeWei + ',';
        }
        
        //Check for size
        else if(barChartDataBR.size() > 0) {
        	
        	//Loop over wrapper list and set colors to it
        	for(BarChartDataWrapperBR dataForBR : barChartDataBR)
	            colorCodes += dataForBR.colorCode + ',' + dataForBR.colorCodeZero + ',' + dataForBR.colorCodeWei + ',';
        }
        return colorCodes;
    }
     
    /**
     *  Description     :   BarChartDataWrapper class to hold chart data for schedules.
     **/
    public class BarChartDataWrapper{
    	
    	//Declarations
    	public String colorCode {get; set;}
        public String colorCodeZero {get; set;}
    	public String colorCodeWei {get; set;}
        public Decimal Recognized {set;get;}
        public Decimal Deferred {set;get;}
        public Decimal RecognizedWeighted {set;get;}
        public Decimal DeferredWeighted {set;get;}
        public String transDate {set;get;}
        public Decimal Forecasted {set;get;}
        public Decimal totalForecastedZero {set;get;}
        public Decimal ForecastedWeighted {set;get;}
        public Date schDate {get; set;}
        public Decimal RecognizedCumulative {get; set;}
        public Decimal RecognizedWeightedCumulative {get; set;}
        public Decimal ForecastedCumulative {get; set;}
        public Decimal ForecastedWeiCummulative {set;get;}
        
        //Constructor
        public BarChartDataWrapper(String colorCode, String colorCodeZero, String colorCodeWei, Decimal Recognized, Decimal Deferred, 
                                   Decimal RecognizedWeighted, Decimal DeferredWeighted, String transDate, Decimal Forecasted, 
                                   Decimal totalForecastedZero, Decimal ForecastedWeighted, Date schDate, Decimal RecognizedCumulative,
                                   Decimal RecognizedWeightedCumulative, Decimal ForecastedCumulative, Decimal ForecastedWeiCummulative) {
            
            //Assigning in wrapper variable
            this.colorCode = colorCode;
            this.colorCodeZero = colorCodeZero;
            this.colorCodeWei = colorCodeWei;
            this.Recognized = Recognized;
            this.Deferred = Deferred;
            this.RecognizedWeighted = RecognizedWeighted;
            this.DeferredWeighted = DeferredWeighted;
            this.transDate = transDate;
            this.Forecasted = Forecasted;
            this.totalForecastedZero = totalForecastedZero;
            this.ForecastedWeighted = ForecastedWeighted;
            this.schDate = schDate;
            this.RecognizedCumulative = RecognizedCumulative;
            this.RecognizedWeightedCumulative = RecognizedWeightedCumulative;
            this.ForecastedCumulative = ForecastedCumulative;
            this.ForecastedWeiCummulative = ForecastedWeiCummulative;
                                       
            this.colorCode = '#006400'; //Dark Green Color
	       	if(this.schDate > Date.today()){
	           this.colorCode = '#0000FF'; //Blue Color
	       	}
	       	this.colorCodeZero = '#FFFFFF'; //White color
	       	this.colorCodeWei = '#FF6600'; //Orange Color
	       	if(this.schDate > Date.today()){
	           this.colorCodeWei = '#FFFF00'; //Yellow Color
	       	}
        }
    } 
    
    /**
     *  Description     :   BarChartDataWrapper class to hold chart data for schedules.
     **/
    public class BarChartDataWrapperBR{
    	
    	//Declarations
    	public String colorCode {get; set;}
        public String colorCodeZero {get; set;}
    	public String colorCodeWei {get; set;}
        public Decimal Recognized {set;get;}
        public Decimal Deferred {set;get;}
        public Decimal RecognizedWeighted {set;get;}
        public Decimal DeferredWeighted {set;get;}
        public Decimal Forecasted {set;get;}
        public Decimal totalForecastedZero {set;get;}
        public Decimal ForecastedWeighted {set;get;}
        public String chartDate {set;get;}
        public Date schDate {get; set;}
        public Decimal RecognizedCumulative {get; set;}
        public Decimal RecognizedWeightedCumulative {get; set;}
        public Decimal ForecastedCumulative {get; set;}
        public Decimal ForecastedWeiCummulative {get; set;}
        
        //Constructor
        public BarChartDataWrapperBR(String colorCode, String colorCodeZero, String colorCodeWei, Decimal Recognized, Decimal Deferred, 
                                     Decimal RecognizedWeighted, Decimal DeferredWeighted, Decimal Forecasted, Decimal totalForecastedZero, 
                                     Decimal ForecastedWeighted, String chartDate, Date schDate, Decimal RecognizedCumulative, 
                                     Decimal RecognizedWeightedCumulative, Decimal ForecastedCumulative, Decimal ForecastedWeiCummulative) {
            
            //Assigning in wrapper variable
            this.colorCode = colorCode;
            this.colorCodeZero = colorCodeZero;
            this.colorCodeWei = colorCodeWei;
            this.Recognized = Recognized;
            this.Deferred = Deferred;
            this.RecognizedWeighted = RecognizedWeighted;
            this.DeferredWeighted = DeferredWeighted;
            this.Forecasted = Forecasted;
            this.totalForecastedZero = totalForecastedZero;
            this.ForecastedWeighted = ForecastedWeighted;
            this.chartDate = chartDate;
            this.schDate = schDate;
            this.RecognizedCumulative = RecognizedCumulative;
            this.RecognizedWeightedCumulative = RecognizedWeightedCumulative;
            this.ForecastedCumulative = ForecastedCumulative;
            this.ForecastedWeiCummulative = ForecastedWeiCummulative;
                                         
            this.colorCode = '#006400'; //Dark Green Color
	       	if(this.schDate > Date.today()){
	           this.colorCode = '#0000FF'; //Blue Color
	       	}
	       	this.colorCodeZero = '#FFFFFF'; //White color
	       	this.colorCodeWei = '#FF6600'; //Orange Color
	       	if(this.schDate > Date.today()){
	           this.colorCodeWei = '#FFFF00'; //Yellow Color
	       	}
        }
    } 
    
    /**
     *  Description     :   Class to hold page table data.
     **/
    public Class RevRecLineItemScheduleWrapper {
        
        //Declarations
        public RevRecOpportunityLineItemSchedule__c schedule {get; set;}
        public Decimal recognizedCumulative {get; set;}
        public Decimal recognizedWeiCumulative {get; set;}
        public Decimal forecastedCumulative {get; set;}
        
        //Constructor
        public RevRecLineItemScheduleWrapper(RevRecOpportunityLineItemSchedule__c schedule, Decimal recognizedCumulative, Decimal recognizedWeiCumulative, Decimal forecastedCumulative) {
            this.schedule = schedule;
            this.recognizedCumulative = recognizedCumulative;
            this.recognizedWeiCumulative = recognizedWeiCumulative;
            this.forecastedCumulative = forecastedCumulative;
        }
    }
 }