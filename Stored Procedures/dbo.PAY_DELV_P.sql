SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PAY_DELV_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
      BEGIN TRAN PAY_DELV_P_T1
      DECLARE @ErrorMessage NVARCHAR(MAX);
 	   -- بررسی دسترسی کاربر
      DECLARE @AP BIT
             ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>117</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 117 سطوح امینتی : شما مجوز بستن و تحویل درآمد های صندوق را ندارید', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END   
      -- پایان دسترسی
      
      DECLARE @DelvDate DATETIME
             ,@FromDate DATE
             ,@ToDate   DATE
             ,@CashBy   VARCHAR(250);
      
      SET @DelvDate =  GETDATE();
      SELECT @CashBy = @X.query('//Payment').value('(Payment/@cashby)[1]', 'VARCHAR(250)')
            ,@FromDate = @X.query('//Payment').value('(Payment/@fromdate)[1]', 'DATE')
            ,@ToDate = @X.query('//Payment').value('(Payment/@todate)[1]', 'DATE');
      
      UPDATE Payment
	     SET DELV_STAT = '002'
	        ,DELV_DATE = @DelvDate
	        ,DELV_BY   = UPPER(SUSER_NAME())
	   WHERE DELV_STAT = '001'
	     AND CASH_BY = @CashBy
	     AND CLUB_CODE_DNRM IN (
		      SELECT CLUB_CODE
		        FROM V#UCFGA
		       --WHERE UPPER(SYS_USER) = UPPER(COALESCE(Q.CashBy, SUSER_NAME()))	         
		       WHERE UPPER(SYS_USER) = UPPER(COALESCE(/*Q.CashBy*/NULL, SUSER_NAME()))	         
	     )
	     AND RQST_RQID IN (
	      SELECT R.RQID
	        FROM Request R
	       WHERE R.RQST_STAT <> '003'
	         --**--AND (@FromDate IN ( '1900-01-01' , '0001-01-01' ) OR CAST(R.SAVE_DATE AS DATE)  >= @FromDate)
            --**--AND (@ToDate   IN ( '1900-01-01' , '0001-01-01' ) OR CAST(R.SAVE_DATE AS DATE)  <= @ToDate)
	         AND R.REGN_PRVN_CODE + R.REGN_CODE IN (
	            SELECT REGN_PRVN_CODE + REGN_CODE
	              FROM V#URFGA
	             --WHERE UPPER(SYS_USER) = UPPER(COALESCE(@CashBy, SUSER_NAME()))
	             WHERE UPPER(SYS_USER) = UPPER(COALESCE(/*@CashBy*/NULL, SUSER_NAME()))
	       )
	     )
	     AND EXISTS(
	      SELECT *
	        FROM Payment_Method Pm
	       WHERE Pm.PYMT_CASH_CODE = Payment.CASH_CODE
	         AND Pm.PYMT_RQST_RQID = Payment.RQST_RQID
	         AND (@FromDate IN ( '1900-01-01' , '0001-01-01' ) OR CAST(Pm.ACTN_DATE AS DATE)  >= @FromDate)
	         AND (@ToDate   IN ( '1900-01-01' , '0001-01-01' ) OR CAST(Pm.ACTN_DATE AS DATE)  <= @ToDate)
	     );
	   
	   --SELECT * FROM Payment;
	   
	   
	   /* بعد از این مرحله سند اتوماتیک زده میشود که کامپیوتر کاربر دریافت کننده عمل پرینت دریافت و پرداخت را انجام دهد */
   	DECLARE @Amnt BIGINT;
   	
	   SELECT @Amnt = SUM (P.SUM_RCPT_EXPN_PRIC + P.SUM_RCPT_EXPN_EXTR_PRCT)
	     FROM Payment P
	    WHERE P.DELV_STAT = '002'
	      AND P.DELV_DATE = @DelvDate
	      AND DELV_BY = UPPER(SUSER_NAME())
	      AND CASH_BY = @CashBy
	      AND CLUB_CODE_DNRM IN (
		      SELECT CLUB_CODE
		        FROM V#UCFGA
		       --WHERE UPPER(SYS_USER) = UPPER(COALESCE(Q.CashBy, SUSER_NAME()))	         
		       WHERE UPPER(SYS_USER) = UPPER(COALESCE(/*Q.CashBy*/NULL, SUSER_NAME()))	         
	     )
	     AND RQST_RQID IN (
	      SELECT R.RQID
	        FROM Request R
	       WHERE R.RQST_STAT <> '003'
	         --**--AND (@FromDate IN ( '1900-01-01' , '0001-01-01' ) OR CAST(R.SAVE_DATE AS DATE)  >= @FromDate)
            --**--AND (@ToDate   IN ( '1900-01-01' , '0001-01-01' ) OR CAST(R.SAVE_DATE AS DATE)  <= @ToDate)
	         AND R.REGN_PRVN_CODE + R.REGN_CODE IN (
	            SELECT REGN_PRVN_CODE + REGN_CODE
	              FROM V#URFGA
	             --WHERE UPPER(SYS_USER) = UPPER(COALESCE(@CashBy, SUSER_NAME()))
	             WHERE UPPER(SYS_USER) = UPPER(COALESCE(/*@CashBy*/NULL, SUSER_NAME()))
	       )
	     )
	     AND EXISTS(
	      SELECT *
	        FROM Payment_Method Pm
	       WHERE Pm.PYMT_CASH_CODE = P.CASH_CODE
	         AND Pm.PYMT_RQST_RQID = P.RQST_RQID
	         AND (@FromDate IN ( '1900-01-01' , '0001-01-01' ) OR CAST(Pm.ACTN_DATE AS DATE)  >= @FromDate)
	         AND (@ToDate   IN ( '1900-01-01' , '0001-01-01' ) OR CAST(Pm.ACTN_DATE AS DATE)  <= @ToDate)
	     );
   	
	   DECLARE @PX XML;
	   SELECT @PX = (
	      SELECT 0 AS '@raid'
	            ,@CashBy AS '@fromuser'
	            ,@Amnt AS '@amnt'
	            ,'003' AS '@rcanstat'
	            ,'002' AS '@autodoc'
	            ,GETDATE() AS '@actndate'
	      FOR XML PATH('Receipt_Announcement'), ROOT('Receipt_Announcements')
	   )
	   EXEC CRET_RCAN_P @PX;
	   COMMIT TRAN PAY_DELV_P_T1;
	END TRY
	BEGIN CATCH
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
	   ROLLBACK TRAN PAY_DELV_P_T1;
	END CATCH
END
GO
