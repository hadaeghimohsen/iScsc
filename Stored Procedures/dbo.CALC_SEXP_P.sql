SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_SEXP_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRANSACTION [T$CALC_SEXP_P];
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>242</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 242 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @Rqid BIGINT;
	SELECT @Rqid = @x.query('Request').value('(Request/@rqid)[1]', 'BIGINT');
	
	IF NOT EXISTS(SELECT * FROM dbo.Request WHERE RQID = @Rqid AND RQTT_CODE = '001')
	   SELECT @Rqid = RQST_RQID
	     FROM dbo.Request
	    WHERE RQID = @Rqid;
	  
	SELECT @X = (
     SELECT @Rqid '@rqid'          
           ,RQTP_CODE '@rqtpcode'
           ,RQTT_CODE '@rqttcode'
           ,REGN_CODE '@regncode'  
           ,REGN_PRVN_CODE '@prvncode'
       FROM dbo.Request
      WHERE RQID = @Rqid
     FOR XML PATH('Request'), ROOT('Process')
   );
   EXEC INS_SEXP_P @X;
   
   -- اصلاح ساعت کلاسی مشتری در جدول زیر هزینه
   IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @Rqid AND RQTP_CODE IN ('001', '009'))
   BEGIN
      UPDATE p
         SET p.CBMT_CODE_DNRM = fp.CBMT_CODE
            ,p.FIGH_FILE_NO = fp.COCH_FILE_NO
        FROM dbo.Payment_Detail p, dbo.Member_Ship ms, dbo.Fighter_Public fp
       WHERE p.PYMT_RQST_RQID = @Rqid
         AND ms.RQRO_RQST_RQID = @Rqid 
         AND ms.RECT_CODE = CASE ms.RWNO WHEN 1 THEN '001' ELSE '004' END
         AND fp.FIGH_FILE_NO = ms.FIGH_FILE_NO                  
         AND fp.RWNO = CASE ms.RWNO WHEN 1 THEN 1 ELSE ms.FGPB_RWNO_DNRM END
         AND fp.RECT_CODE = '004';
   END;
   
   COMMIT TRANSACTION [T$CALC_SEXP_P];
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T$CALC_SEXP_P]
   END CATCH
END
GO
