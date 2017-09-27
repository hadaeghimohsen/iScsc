SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CONF_EXPN_P]
	@X XML
AS
BEGIN
   -- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
   
   BEGIN TRY 
   BEGIN TRAN T1
   DECLARE @CalcExpnType VARCHAR(3);
   SELECT @CalcExpnType = @X.query('//Misc_Expenses').value('(Misc_Expenses/@calcexpntype)[1]', 'VARCHAR(3)');
   
   IF @CalcExpnType = '001'
   BEGIN
   	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>129</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 129 سطوح امینتی : شما مجوز تایید پرداخت هزینه مربیان را ندارید', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END

      UPDATE Payment_Expense
         SET VALD_TYPE = '002'
       WHERE VALD_TYPE = '001';       
   END
   ELSE
   BEGIN
   	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>214</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 214 سطوح امینتی : شما مجوز تایید پرداخت هزینه متفرقه را ندارید', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END   
   END
   
   MERGE Misc_Expense T
   USING (SELECT  r.query('.').value('(Misc_Expense/@code)[1]', 'BIGINT') Code
                 --,r.query('.').value('(Misc_Expense/@cochfileno)[1]', 'BIGINT') CochFileNo
                 ,r.query('.').value('(Misc_Expense/@delvby)[1]', 'nvarchar(250)') DelvBy
                 ,r.query('.').value('(Misc_Expense/@delvdate)[1]', 'DATE') DelvDate
                 ,r.query('Expn_Desc').value('.', 'NVARCHAR(500)') ExpnDesc
            FROM @X.nodes('//Misc_Expense') T(r)) S
   ON (T.Code = S.Code)
   WHEN MATCHED THEN
      UPDATE 
         SET Vald_Type = '002'
            ,Delv_Stat = '002'
            ,Delv_Date = CASE WHEN S.DelvDate IN ('1900-01-01', '0001-01-01') THEN GETDATE() ELSE S.DelvDate END
            ,Delv_By   = CASE WHEN LEN(S.DelvBy) = 0 OR S.DelvBy IS NULL THEN (SELECT Name_Dnrm FROM Fighter WHERE File_No = T.Coch_File_No) ELSE S.DelvBy END
            ,Expn_Desc = S.ExpnDesc;
   COMMIT TRAN T1
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END
GO
