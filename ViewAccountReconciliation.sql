Alter Table account_reconciliation
Add Account_Id int default null;

ALTER TABLE account_reconciliation
ADD CONSTRAINT FK_Account_Id
FOREIGN KEY (Account_ID) REFERENCES Accounts_ID(id);

Alter Table account_reconciliation
Add Bank_Statement decimal(22,2) DEFAULT NULL;

drop table account_reconciliation_Junction;

drop view if exists vw_account_reconciliation; 
CREATE 
VIEW `vw_account_reconciliation` AS
    SELECT 
        `a`.`ID` AS `ID`,
        `a`.`ENTRY_DATE` AS `ENTRY_DATE`,
        `a`.`ENTERED_BY` AS `ENTERED_BY`,
        `a`.`COMPANY_ID` AS `COMPANY_ID`,
        `a`.`Bank_Statement` AS `BANK_STATEMENT`,
        `b`.`ACC_ID` AS `ACC_ID`,
        `b`.`ID` AS `ACCOUNT_ID`
    FROM
        (`account_reconciliation` `a`
        LEFT JOIN `accounts_id` `b` ON ((`a`.`Account_Id` = `b`.`ID`)))
    ORDER BY `a`.`ID` DESC;