

drop procedure if Exists PROC_ACCOUNT_RECONCILIATION;
DELIMITER $$
CREATE  PROCEDURE `PROC_ACCOUNT_RECONCILIATION`(
												 P_ENTRY_DATE TEXT,
												 P_ACCOUNT_ID INT,
												 P_COMPANY_ID INT,
												 P_FORM Text
												)

BEGIN

Declare Date_From Text;
Declare Date_To Text;
Declare Account_Type int;
DECLARE _rollback BOOL DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		SHOW ERRORS;
        ROLLBACK;
        ReSignal;
END;

select CAST(DATE_FORMAT(convert(P_ENTRY_DATE,Date) ,'%Y-%m-01') as DATE) into Date_From;
SELECT LAST_DAY(convert(P_ENTRY_DATE,Date)) into Date_To;

select account_type.ACCOUNT_ID
into 
       Account_Type 
from
       accounts_id 
inner join
       account_type
on
       account_type.id=accounts_id.ACCOUNT_TYPE_ID
where 
       accounts_id.id=P_ACCOUNT_ID;

											if P_FORM = 'CREATE'
											then
													
                                                    select 
															A.id,
															CASE
															
																	WHEN (A.GL_FLAG = 57) THEN A.AMOUNT
																	WHEN (A.GL_FLAG = 59) THEN A.AMOUNT
																	WHEN (A.GL_FLAG = 64) THEN A.AMOUNT
															
															END AS DEBIT,
														
															CASE
															
																	WHEN (A.GL_FLAG = 58)  THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 60)  THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 62)  THEN A.AMOUNT 
																	when (A.GL_FLAG = 150) Then A.Amount
																	When (A.GL_FLAG = 151) Then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 57 OR A.GL_FLAG = 58 OR A.GL_FLAG = 59 OR A.GL_FLAG = 60 OR A.GL_FLAG = 150 OR A.GL_FLAG = 151 THEN 'Stock Transfer'
																	WHEN A.GL_FLAG = 62  OR A.GL_FLAG = 64 THEN 'Stock In'
															End as Form_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'N'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'Y'
															End as IS_Conflicted,
                                                            A.IS_CONFLICTED as Orignal_Is_Conflicted,
                                                            A.Reconcile_Date,
                                                            'stock_accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'Y'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'N'
															End as IS_Virtual
                                                            
													FROM   Stock_Accounting A
													where  (
																convert(A.Form_Date,Date) <=  convert(Date_To,date)
																And    
                                                                A.Company_Id = P_COMPANY_ID
																And    
                                                                A.Is_Conflicted = 'N'
                                                                And 
																A.GL_ACC_ID = P_ACCOUNT_ID
															)
                                                    OR     (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  OR 
															(
																Convert(A.FORM_DATE,date) <= Convert(Date_To,Date)
                                                                And
                                                                Convert(A.Reconcile_Date,date) > Convert(Date_To,Date)
                                                                And
                                                                A.Is_Conflicted = 'Y'
																AND 
																A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                                
                                                            
                                                            )
                                                            
														  Union All 
                                                            
                                                          select 
															A.id,
															CASE
															
																	WHEN (A.GL_FLAG = 74) THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 75) THEN A.AMOUNT
															
															END AS DEBIT,
														
															CASE
															
																	WHEN (A.GL_FLAG = 73) THEN A.AMOUNT
																	WHEN (A.GL_FLAG = 76) THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 77) THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 78) THEN A.AMOUNT 
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 75 OR A.GL_FLAG = 76 or A.GL_FLAG = 77 OR A.GL_FLAG = 78 THEN 'Repair IN'
																	WHEN A.GL_FLAG = 73 OR A.GL_FLAG = 74 THEN 'Repair Out'
															End as Form_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y' then 'N'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'Y'
															End as IS_Conflicted,
                                                            A.IS_CONFLICTED as Orignal_Is_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Repair_Accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'Y'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'N'
															End as IS_Virtual
                                                            
													FROM   Repair_Accounting A
													where  (
																convert(A.Form_Date,Date) <=  convert(Date_To,date)
																And    
                                                                A.Company_Id = P_COMPANY_ID
																And    
                                                                A.Is_Conflicted = 'N'
                                                                And 
																A.GL_ACC_ID = P_ACCOUNT_ID
															)
                                                    OR     (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  OR 
															(
																Convert(A.FORM_DATE,date) <= Convert(Date_To,Date)
                                                                And
                                                                Convert(A.Reconcile_Date,date) > Convert(Date_To,Date)
                                                                And
                                                                A.Is_Conflicted = 'Y'
																AND
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            
                                                            )
													
                                                    Union All 
                                                    
                                                    select 
															A.id,
															CASE
															
																 WHEN (A.GL_FLAG = 510) then A.Amount			
																 When (A.GL_FLAG = 16)  then A.Amount
																 When (A.GL_FLAG = 513) then A.Amount
																 When (A.GL_FLAG = 19)  then A.Amount 
																 When (A.GL_FLAG = 26)  then A.Amount 
																 When (A.GL_FLAG = 201) then A.Amount
																 When (A.GL_FLAG = 203) then A.Amount 
																 When (A.GL_FLAG = 103) then A.Amount 
																 When (A.GL_FLAG = 105) then A.Amount
																 When (A.GL_FLAG = 107) then A.Amount
																 When (A.GL_FLAG = 204) then A.Amount			
																 When (A.GL_FLAG = 205) then A.Amount
																 When (A.GL_FLAG = 110) then A.Amount 
																 When (A.GL_FLAG = 113) then A.Amount 
																 When (A.GL_FLAG = 112) then A.Amount 
																 When (A.GL_FLAG = 5551) then A.Amount 
																 When (A.GL_FLAG = 89)  then A.Amount
																 When (A.GL_FLAG = 116) then A.Amount
																 When (A.GL_FLAG = 117) then A.Amount
																 When (A.GL_FLAG = 5553) then A.Amount
															
															END AS DEBIT,
														
															CASE
															
																 When (A.GL_FLAG = 511) then A.Amount
																 When (A.GL_FLAG = 15)  then A.Amount
																 When (A.GL_FLAG = 512) then A.Amount 
																 When (A.GL_FLAG = 20)  then A.Amount
																 When (A.GL_FLAG = 101) then A.Amount 
																 When (A.GL_FLAG = 23)  then A.Amount
																 When (A.GL_FLAG = 102) then A.Amount 
																 When (A.GL_FLAG = 104) then A.Amount 
																 When (A.GL_FLAG = 106) then A.Amount
																 When (A.GL_FLAG = 29)  then A.Amount 
																 When (A.GL_FLAG = 28)  then A.Amount  
																 When (A.GL_FLAG = 108) then A.Amount 
																 When (A.GL_FLAG = 109) then A.Amount 
																 When (A.GL_FLAG = 111) then A.Amount 
																 When (A.GL_FLAG = 114) then A.Amount
																 When (A.GL_FLAG = 5552) then A.Amount 																 
																 When (A.GL_FLAG = 115) then A.Amount 
																 When (A.GL_FLAG = 90)  then A.Amount
																 When (A.GL_FLAG = 5554) then A.Amount 
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 15 OR A.GL_FLAG = 16 OR A.GL_FLAG = 510 OR A.GL_FLAG = 511 THEN 'Payment Sent'
																	WHEN A.GL_FLAG = 19 OR A.GL_FLAG = 20 OR A.GL_FLAG = 512 OR A.GL_FLAG = 513 THEN 'Receive Money'
                                                                    WHEN A.GL_FLAG = 101 OR A.GL_FLAG = 26 OR A.GL_FLAG = 23 OR A.GL_FLAG = 201 OR A.GL_FLAG = 102 OR A.GL_FLAG = 203 OR A.GL_FLAG = 103 OR A.GL_FLAG = 104 OR A.GL_FLAG = 105 OR A.GL_FLAG = 106 OR A.GL_FLAG = 5553 OR A.GL_FLAG=5554 THEN 'Payments'
                                                                    WHEN A.GL_FLAG = 107 OR A.GL_FLAG = 29 OR A.GL_FLAG = 28 OR A.GL_FLAG = 204 OR A.GL_FLAG = 205 OR A.GL_FLAG = 108 OR A.GL_FLAG = 109 OR A.GL_FLAG = 110 OR A.GL_FLAG = 111 OR A.GL_FLAG = 113 OR A.GL_FLAG = 114 OR A.GL_FLAG = 112 OR A.GL_FLAG = 5552 OR A.GL_FLAG =5551 THEN 'Receipts'
																	WHEN A.GL_FLAG = 115 OR A.GL_FLAG = 89 OR A.GL_FLAG = 90 OR A.GL_FLAG = 116 OR A.GL_FLAG = 117 THEN 'CHARGES'
                                                            End as Form_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'N'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'Y'
															End as IS_Conflicted,
                                                            A.IS_CONFLICTED as Orignal_Is_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Payments_Accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'Y'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'N'
															End as IS_Virtual
                                                            
													FROM   Payments_Accounting A
													where  (
																convert(A.Form_Date,Date) <=  convert(Date_To,date)
																And    
                                                                A.Company_Id = P_COMPANY_ID
																And    
                                                                A.Is_Conflicted = 'N'
                                                                And 
																A.GL_ACC_ID = P_ACCOUNT_ID
															)
                                                    OR     (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  OR 
															(
																Convert(A.FORM_DATE,date) <= Convert(Date_To,Date)
                                                                And
                                                                Convert(A.Reconcile_Date,date) > Convert(Date_To,Date)
                                                                And
                                                                A.Is_Conflicted = 'Y'
																AND 
																A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                               
                                                            )
                                                    
                                                     Union All 
                                                     
                                                      select 
															A.id,
															CASE
															
																When (A.GL_FLAG = 41) then A.Amount
																When (A.GL_FLAG = 43) then A.Amount 
																When (A.GL_FLAG = 45) then A.Amount 
																When (A.GL_FLAG = 48) then A.Amount 
																When (A.GL_FLAG = 82) then A.Amount 
																When (A.GL_FLAG = 83) then A.Amount 
																When (A.GL_FLAG = 84) then A.Amount 
																When (A.GL_FLAG = 49) then A.Amount 
																When (A.GL_FLAG = 52) then A.Amount
																When (A.GL_FLAG = 100) then A.Amount 																
																When (A.GL_FLAG = 53) then A.Amount 
																When (A.GL_FLAG = 55) then A.Amount 
															
															END AS DEBIT,
														
															CASE
															
															  When (A.GL_FLAG = 42) then A.Amount 
															  When (A.GL_FLAG = 44) then A.Amount 
															  When (A.GL_FLAG = 79) then A.Amount 
															  When (A.GL_FLAG = 80) then A.Amount 
															  When (A.GL_FLAG = 81) then A.Amount 
															  When (A.GL_FLAG = 46) then A.Amount 
															  When (A.GL_FLAG = 47) then A.Amount 
															  When (A.GL_FLAG = 50) then A.Amount 
															  When (A.GL_FLAG = 51) then A.Amount 
															  When (A.GL_FLAG = 54) then A.Amount 
															  when (A.GL_FLAG = 56) then A.Amount 
															  When (A.GL_FLAG = 86) then A.Amount 
															  When (A.GL_FLAG = 87) then A.Amount 
															  When (A.GL_FLAG = 85) then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 41 OR A.GL_FLAG = 42 OR A.GL_FLAG = 43 OR A.GL_FLAG = 44 OR A.GL_FLAG = 79 OR A.GL_FLAG = 80 OR A.GL_FLAG = 81 THEN 'Sale Invoice'
                                                                    WHEN A.GL_FLAG = 45 OR A.GL_FLAG = 46 OR A.GL_FLAG = 47 OR A.GL_FLAG = 48  OR A.GL_FLAG = 82 OR A.GL_FLAG = 83 OR A.GL_FLAG = 84 THEN 'Sale Return'
                                                                    WHEN A.GL_FLAG = 49 OR A.GL_FLAG = 50 OR A.GL_FLAG = 51 OR A.GL_FLAG = 52 OR A.GL_FLAG = 53 OR A.GL_FLAG = 54 OR A.GL_FLAG = 55 OR A.GL_FLAG = 56  OR A.GL_FLAG = 85 OR A.GL_FLAG = 86 OR A.GL_FLAG = 87 OR A.GL_FLAG = 100 THEN 'Replacement'
                                                            End as Form_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'N'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'Y'
															End as IS_Conflicted,
                                                            A.IS_CONFLICTED as Orignal_Is_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Sales_Accounting ' as Accounting_Tables,
                                                            Account_Type as Account_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'Y'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'N'
															End as IS_Virtual
                                                            
													FROM   Sales_Accounting  A
													where  (
																convert(A.Form_Date,Date) <=  convert(Date_To,date)
																And    
                                                                A.Company_Id = P_COMPANY_ID
																And    
                                                                A.Is_Conflicted = 'N'
                                                                And 
																A.GL_ACC_ID = P_ACCOUNT_ID
															)
                                                    OR     (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  OR 
															(
																Convert(A.FORM_DATE,date) <= Convert(Date_To,Date)
                                                                And
                                                                Convert(A.Reconcile_Date,date) > Convert(Date_To,Date)
                                                                And
                                                                A.Is_Conflicted = 'Y'
																AND 
																A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                                
                                                            )
                                                    
                                                            Union All 
                                                            
                                                            select 
															A.id,
															CASE
															
																When (A.GL_FLAG = 32) then A.Amount 
																When (A.GL_FLAG = 33) then A.Amount 
																When (A.GL_FLAG = 37) then A.Amount 
																When (A.GL_FLAG = 39) then A.Amount
															
															END AS DEBIT,
														
															CASE
															
																When (A.GL_FLAG = 31) then A.Amount 
																When (A.GL_FLAG = 34) then A.Amount 
																When (A.GL_FLAG = 38) then A.Amount 
																When (A.GL_FLAG = 40) then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 39 OR A.GL_FLAG = 40 THEN 'Vendor Credit Memo'
                                                                    WHEN A.GL_FLAG = 31 OR A.GL_FLAG = 32 OR A.GL_FLAG = 33 OR A.GL_FLAG = 34 THEN 'Partial Credit'
                                                                    WHEN A.GL_FLAG = 37 OR A.GL_FLAG = 38 THEN 'Receive Order'
                                                            End as Form_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'N'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'Y'
															End as IS_Conflicted,
                                                            A.IS_CONFLICTED as Orignal_Is_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Purchase_Accounting  ' as Accounting_Tables,
                                                            Account_Type as Account_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'Y'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'N'
															End as IS_Virtual
                                                            
													FROM   Purchase_Accounting   A
													where  (
																convert(A.Form_Date,Date) <=  convert(Date_To,date)
																And    
                                                                A.Company_Id = P_COMPANY_ID
																And    
                                                                A.Is_Conflicted = 'N'
                                                                And 
																A.GL_ACC_ID = P_ACCOUNT_ID
															)
                                                    OR     (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  OR 
															(
																Convert(A.FORM_DATE,date) <= Convert(Date_To,Date)
                                                                And
                                                                Convert(A.Reconcile_Date,date) > Convert(Date_To,Date)
                                                                And
                                                                A.Is_Conflicted = 'Y'
																AND 
																A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                               
                                                            )
                                                            
													Union All 
                                                    
                                                    select 
															A.id,
															CASE
															
																 When (A.GL_FLAG = 66) then A.Amount 
																 When (A.GL_FLAG = 67) then A.Amount 
																 When (A.GL_FLAG = 69) then A.Amount
																 When (A.GL_FLAG = 71) then A.Amount
															
															END AS DEBIT,
														
															CASE
															
																When (A.GL_FLAG = 65) then A.Amount 
																When (A.GL_FLAG = 68) then A.Amount 
																When (A.GL_FLAG = 70) then A.Amount 
																When (A.GL_FLAG = 72) then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 65 OR A.GL_FLAG = 66 OR A.GL_FLAG = 67 OR A.GL_FLAG = 68 OR A.GL_FLAG = 69 OR A.GL_FLAG = 70 THEN 'Adjustment'
                                                                    WHEN A.GL_FLAG = 71 OR A.GL_FLAG = 72 THEN 'General Journal' 
                                                                    
                                                            End as Form_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'N'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'Y'
															End as IS_Conflicted,
                                                            A.IS_CONFLICTED as Orignal_Is_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Adjustment_Accounting    ' as Accounting_Tables,
                                                            Account_Type as Account_Type,
                                                            case 
																	when Convert(A.Form_Date,Date) <= Convert(Date_To,Date) and Convert(A.Reconcile_Date,Date) > Convert(Date_To,Date) and A.IS_CONFLICTED='Y'  then 'Y'
                                                                    when Convert(A.FORM_DATE,Date) <= Convert(Date_To,Date) and A.IS_CONFLICTED = 'N' then 'N'
                                                                    when Convert(A.Reconcile_Date,Date) >= Convert(Date_From,Date) and Convert(A.Reconcile_Date,Date) <= Convert(Date_To,Date) and A.IS_Conflicted='Y' then 'N'
															End as IS_Virtual
                                                            
													FROM   Adjustment_Accounting A
													where  (
																convert(A.Form_Date,Date) <=  convert(Date_To,date)
																And    
                                                                A.Company_Id = P_COMPANY_ID
																And    
                                                                A.Is_Conflicted = 'N'
                                                                And 
																A.GL_ACC_ID = P_ACCOUNT_ID
															)
                                                    OR     (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  OR 
															(
																Convert(A.FORM_DATE,date) <= Convert(Date_To,Date)
                                                                And
                                                                Convert(A.Reconcile_Date,date) > Convert(Date_To,Date)
                                                                And
                                                                A.Is_Conflicted = 'Y'
																AND 
																A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                                
                                                            ) Order by IS_CONFLICTED DESC;
															
										END IF;
										
										IF P_FORM = 'LOAD'
										then 
										
												select 
															A.id,
															CASE
															
																	WHEN (A.GL_FLAG = 57) THEN A.AMOUNT
																	WHEN (A.GL_FLAG = 59) THEN A.AMOUNT
																	WHEN (A.GL_FLAG = 64) THEN A.AMOUNT
															
															END AS DEBIT,
														
															CASE
															
																	WHEN (A.GL_FLAG = 58)  THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 60)  THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 62)  THEN A.AMOUNT 
																	when (A.GL_FLAG = 150) Then A.Amount
																	When (A.GL_FLAG = 151) Then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 57 OR A.GL_FLAG = 58 OR A.GL_FLAG = 59 OR A.GL_FLAG = 60 OR A.GL_FLAG = 150 OR A.GL_FLAG = 151 THEN 'Stock Transfer'
																	WHEN A.GL_FLAG = 62  OR A.GL_FLAG = 64 THEN 'Stock In'
															End as Form_Type,
                                                            A.IS_CONFLICTED as  IS_Conflicted,
                                                            A.Reconcile_Date,
                                                            'stock_accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type
													FROM   Stock_Accounting A
													where  
                                                           (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  
													  
													Union All 
                                                            
                                                          select 
															A.id,
															CASE
															
																	WHEN (A.GL_FLAG = 74) THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 75) THEN A.AMOUNT
															
															END AS DEBIT,
														
															CASE
															
																	WHEN (A.GL_FLAG = 73) THEN A.AMOUNT
																	WHEN (A.GL_FLAG = 76) THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 77) THEN A.AMOUNT 
																	WHEN (A.GL_FLAG = 78) THEN A.AMOUNT 
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 75 OR A.GL_FLAG = 76 or A.GL_FLAG = 77 OR A.GL_FLAG = 78 THEN 'Repair IN'
																	WHEN A.GL_FLAG = 73 OR A.GL_FLAG = 74 THEN 'Repair Out'
															End as Form_Type,
                                                            A.IS_CONFLICTED as IS_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Repair_Accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type
													FROM   Repair_Accounting A
													where  (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  
													
                                                    Union All 
                                                    
                                                    select 
															A.id,
															CASE
															
																 WHEN (A.GL_FLAG = 510) then A.Amount			
																 When (A.GL_FLAG = 16)  then A.Amount
																 When (A.GL_FLAG = 513) then A.Amount
																 When (A.GL_FLAG = 19)  then A.Amount 
																 When (A.GL_FLAG = 26)  then A.Amount 
																 When (A.GL_FLAG = 201) then A.Amount
																 When (A.GL_FLAG = 203) then A.Amount 
																 When (A.GL_FLAG = 103) then A.Amount 
																 When (A.GL_FLAG = 105) then A.Amount
																 When (A.GL_FLAG = 107) then A.Amount
																 When (A.GL_FLAG = 204) then A.Amount			
																 When (A.GL_FLAG = 205) then A.Amount
																 When (A.GL_FLAG = 110) then A.Amount 
																 When (A.GL_FLAG = 113) then A.Amount 
																 When (A.GL_FLAG = 112) then A.Amount 
																 When (A.GL_FLAG = 5551) then A.Amount 
																 When (A.GL_FLAG = 89)  then A.Amount
																 When (A.GL_FLAG = 116) then A.Amount
																 When (A.GL_FLAG = 117) then A.Amount
																 When (A.GL_FLAG = 5553) then A.Amount
															
															END AS DEBIT,
														
															CASE
															
																 When (A.GL_FLAG = 511) then A.Amount
																 When (A.GL_FLAG = 15)  then A.Amount
																 When (A.GL_FLAG = 512) then A.Amount 
																 When (A.GL_FLAG = 20)  then A.Amount
																 When (A.GL_FLAG = 101) then A.Amount 
																 When (A.GL_FLAG = 23)  then A.Amount
																 When (A.GL_FLAG = 102) then A.Amount 
																 When (A.GL_FLAG = 104) then A.Amount 
																 When (A.GL_FLAG = 106) then A.Amount
																 When (A.GL_FLAG = 29)  then A.Amount 
																 When (A.GL_FLAG = 28)  then A.Amount  
																 When (A.GL_FLAG = 108) then A.Amount 
																 When (A.GL_FLAG = 109) then A.Amount 
																 When (A.GL_FLAG = 111) then A.Amount 
																 When (A.GL_FLAG = 114) then A.Amount
																 When (A.GL_FLAG = 5552) then A.Amount 																 
																 When (A.GL_FLAG = 115) then A.Amount 
																 When (A.GL_FLAG = 90)  then A.Amount
																 When (A.GL_FLAG = 5554) then A.Amount 
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 15 OR A.GL_FLAG = 16 OR A.GL_FLAG = 510 OR A.GL_FLAG = 511 THEN 'Payment Sent'
																	WHEN A.GL_FLAG = 19 OR A.GL_FLAG = 20 OR A.GL_FLAG = 512 OR A.GL_FLAG = 513 THEN 'Receive Money'
                                                                    WHEN A.GL_FLAG = 101 OR A.GL_FLAG = 26 OR A.GL_FLAG = 23 OR A.GL_FLAG = 201 OR A.GL_FLAG = 102 OR A.GL_FLAG = 203 OR A.GL_FLAG = 103 OR A.GL_FLAG = 104 OR A.GL_FLAG = 105 OR A.GL_FLAG = 106 OR A.GL_FLAG = 5553 OR A.GL_FLAG=5554 THEN 'Payments'
                                                                    WHEN A.GL_FLAG = 107 OR A.GL_FLAG = 29 OR A.GL_FLAG = 28 OR A.GL_FLAG = 204 OR A.GL_FLAG = 205 OR A.GL_FLAG = 108 OR A.GL_FLAG = 109 OR A.GL_FLAG = 110 OR A.GL_FLAG = 111 OR A.GL_FLAG = 113 OR A.GL_FLAG = 114 OR A.GL_FLAG = 112 OR A.GL_FLAG = 5552 OR A.GL_FLAG =5551 THEN 'Receipts'
																	WHEN A.GL_FLAG = 115 OR A.GL_FLAG = 89 OR A.GL_FLAG = 90 OR A.GL_FLAG = 116 OR A.GL_FLAG = 117 THEN 'CHARGES'
                                                            End as Form_Type,
                                                            A.IS_CONFLICTED as IS_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Payments_Accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type
                                                            
													FROM   Payments_Accounting A
													where  (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  
                                                    
                                                     Union All 
                                                     
                                                      select 
															A.id,
															CASE
															
																When (A.GL_FLAG = 41) then A.Amount
																When (A.GL_FLAG = 43) then A.Amount 
																When (A.GL_FLAG = 45) then A.Amount 
																When (A.GL_FLAG = 48) then A.Amount 
																When (A.GL_FLAG = 82) then A.Amount 
																When (A.GL_FLAG = 83) then A.Amount 
																When (A.GL_FLAG = 84) then A.Amount 
																When (A.GL_FLAG = 49) then A.Amount 
																When (A.GL_FLAG = 52) then A.Amount
																When (A.GL_FLAG = 100) then A.Amount 																
																When (A.GL_FLAG = 53) then A.Amount 
																When (A.GL_FLAG = 55) then A.Amount 
															
															END AS DEBIT,
														
															CASE
															
															  When (A.GL_FLAG = 42) then A.Amount 
															  When (A.GL_FLAG = 44) then A.Amount 
															  When (A.GL_FLAG = 79) then A.Amount 
															  When (A.GL_FLAG = 80) then A.Amount 
															  When (A.GL_FLAG = 81) then A.Amount 
															  When (A.GL_FLAG = 46) then A.Amount 
															  When (A.GL_FLAG = 47) then A.Amount 
															  When (A.GL_FLAG = 50) then A.Amount 
															  When (A.GL_FLAG = 51) then A.Amount 
															  When (A.GL_FLAG = 54) then A.Amount 
															  when (A.GL_FLAG = 56) then A.Amount 
															  When (A.GL_FLAG = 86) then A.Amount 
															  When (A.GL_FLAG = 87) then A.Amount 
															  When (A.GL_FLAG = 85) then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 41 OR A.GL_FLAG = 42 OR A.GL_FLAG = 43 OR A.GL_FLAG = 44 OR A.GL_FLAG = 79 OR A.GL_FLAG = 80 OR A.GL_FLAG = 81 THEN 'Sale Invoice'
                                                                    WHEN A.GL_FLAG = 45 OR A.GL_FLAG = 46 OR A.GL_FLAG = 47 OR A.GL_FLAG = 48  OR A.GL_FLAG = 82 OR A.GL_FLAG = 83 OR A.GL_FLAG = 84 THEN 'Sale Return'
                                                                    WHEN A.GL_FLAG = 49 OR A.GL_FLAG = 50 OR A.GL_FLAG = 51 OR A.GL_FLAG = 52 OR A.GL_FLAG = 53 OR A.GL_FLAG = 54 OR A.GL_FLAG = 55 OR A.GL_FLAG = 56  OR A.GL_FLAG = 85 OR A.GL_FLAG = 86 OR A.GL_FLAG = 87 OR A.GL_FLAG = 100 THEN 'Replacement'
                                                            End as Form_Type,
                                                            A.IS_CONFLICTED as IS_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Sales_Accounting ' as Accounting_Tables,
                                                            Account_Type as Account_Type
                                                            
													FROM   Sales_Accounting  A
													where  (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  
                                                    
                                                            Union All 
                                                            
                                                            select 
															A.id,
															CASE
															
																When (A.GL_FLAG = 32) then A.Amount 
																When (A.GL_FLAG = 33) then A.Amount 
																When (A.GL_FLAG = 37) then A.Amount 
																When (A.GL_FLAG = 39) then A.Amount
															
															END AS DEBIT,
														
															CASE
															
																When (A.GL_FLAG = 31) then A.Amount 
																When (A.GL_FLAG = 34) then A.Amount 
																When (A.GL_FLAG = 38) then A.Amount 
																When (A.GL_FLAG = 40) then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 39 OR A.GL_FLAG = 40 THEN 'Vendor Credit Memo'
                                                                    WHEN A.GL_FLAG = 31 OR A.GL_FLAG = 32 OR A.GL_FLAG = 33 OR A.GL_FLAG = 34 THEN 'Partial Credit'
                                                                    WHEN A.GL_FLAG = 37 OR A.GL_FLAG = 38 THEN 'Receive Order'
                                                            End as Form_Type,
                                                            A.IS_CONFLICTED as IS_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Purchase_Accounting  ' as Accounting_Tables,
                                                            Account_Type as Account_Type
                                                            
													FROM   Purchase_Accounting   A
													where   (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            )
													  
                                                            
													Union All 
                                                    
                                                    select 
															A.id,
															CASE
															
																 When (A.GL_FLAG = 66) then A.Amount 
																 When (A.GL_FLAG = 67) then A.Amount 
																 When (A.GL_FLAG = 69) then A.Amount
																 When (A.GL_FLAG = 71) then A.Amount
															
															END AS DEBIT,
														
															CASE
															
																When (A.GL_FLAG = 65) then A.Amount 
																When (A.GL_FLAG = 68) then A.Amount 
																When (A.GL_FLAG = 70) then A.Amount 
																When (A.GL_FLAG = 72) then A.Amount
															
															END AS CREDIT,
                                                            Form_Date,
                                                            Form_Reference,
                                                            case 
																	WHEN A.GL_FLAG = 65 OR A.GL_FLAG = 66 OR A.GL_FLAG = 67 OR A.GL_FLAG = 68 OR A.GL_FLAG = 69 OR A.GL_FLAG = 70 THEN 'Adjustment'
                                                                    WHEN A.GL_FLAG = 71 OR A.GL_FLAG = 72 THEN 'General Journal' 
                                                                    
                                                            End as Form_Type,
                                                            A.IS_CONFLICTED as IS_Conflicted,
                                                            A.Reconcile_Date,
                                                            'Adjustment_Accounting' as Accounting_Tables,
                                                            Account_Type as Account_Type
													FROM   Adjustment_Accounting A
													where   (
																(convert(A.Reconcile_Date,Date)) >=Convert(Date_From,Date) 
														        And
																(convert(A.Reconcile_Date,Date)) <=Convert(Date_To,Date)
                                                                And 
                                                                A.Is_Conflicted = 'Y'
                                                                And 
                                                                A.Company_Id = P_COMPANY_ID
                                                                AND 
                                                                A.GL_ACC_ID = P_ACCOUNT_ID
                                                            );
													    
										
										
										
										END IF;
										
										IF P_FORM = 'Delete'
										then 
											START TRANSACTION;
											update payments_accounting SET IS_CONFLICTED = 'N',Reconcile_Date = '1999-01-01 00:00:00' where GL_ACC_ID = P_ACCOUNT_ID and Company_Id = P_COMPANY_ID and convert(Reconcile_Date,date) >=Convert(Date_From,Date)  and convert(Reconcile_Date,date) <=Convert(Date_To,Date);
											update Purchase_Accounting SET IS_CONFLICTED = 'N',Reconcile_Date = '1999-01-01 00:00:00' where GL_ACC_ID = P_ACCOUNT_ID and Company_Id = P_COMPANY_ID and convert(Reconcile_Date,date) >=Convert(Date_From,Date)  and convert(Reconcile_Date,date) <=Convert(Date_To,Date);
											update Sales_Accounting SET IS_CONFLICTED = 'N',Reconcile_Date = '1999-01-01 00:00:00' where GL_ACC_ID = P_ACCOUNT_ID and Company_Id = P_COMPANY_ID and convert(Reconcile_Date,date) >=Convert(Date_From,Date)  and convert(Reconcile_Date,date) <=Convert(Date_To,Date);
											update stock_accounting SET IS_CONFLICTED = 'N',Reconcile_Date = '1999-01-01 00:00:00' where GL_ACC_ID = P_ACCOUNT_ID and Company_Id = P_COMPANY_ID and convert(Reconcile_Date,date) >=Convert(Date_From,Date)  and convert(Reconcile_Date,date) <=Convert(Date_To,Date);
											update Repair_Accounting SET IS_CONFLICTED = 'N',Reconcile_Date = '1999-01-01 00:00:00' where GL_ACC_ID = P_ACCOUNT_ID and Company_Id = P_COMPANY_ID and convert(Reconcile_Date,date) >=Convert(Date_From,Date)  and convert(Reconcile_Date,date) <=Convert(Date_To,Date);
											update Adjustment_Accounting SET IS_CONFLICTED = 'N',Reconcile_Date = '1999-01-01 00:00:00' where GL_ACC_ID = P_ACCOUNT_ID and Company_Id = P_COMPANY_ID and convert(Reconcile_Date,date) >=Convert(Date_From,Date)  and convert(Reconcile_Date,date) <=Convert(Date_To,Date);
											COMMIT;
										
										End if;
										
																	

END $$
DELIMITER ;
