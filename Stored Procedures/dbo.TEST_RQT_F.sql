SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TEST_RQT_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @Rqid BIGINT
	       ,@RqroRwno SMALLINT
	       ,@FileNo BIGINT
	       ,@MtodCode BIGINT
	       ,@CtgyCode BIGINT
	       ,@GlobCode VARCHAR(20)
	       ,@CrtfDate DATE
	       ,@CrtfNumb VARCHAR(20)
	       ,@TestDate DATE
	       ,@Rslt     VARCHAR(3);
	       
	       
	SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	      ,@RqroRwno = @X.query('//Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT')
	      ,@FileNo = @X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT')
	      ,@MtodCode = @X.query('//Test').value('(Test/@ctgymtodcode)[1]', 'BIGINT')
	      ,@CtgyCode = @X.query('//Test').value('(Test/@ctgycode)[1]', 'BIGINT')
	      ,@GlobCode = @X.query('//Test').value('(Test/@globcode)[1]', 'VARCHAR(20)')
	      ,@CrtfDate = @X.query('//Test').value('(Test/@crtfdate)[1]', 'DATE')
	      ,@CrtfNumb = @X.query('//Test').value('(Test/@crtfnumb)[1]', 'VARCHAR(20)')
	      ,@TestDate = @X.query('//Test').value('(Test/@testdate)[1]', 'DATE')
	      ,@rslt     = @X.query('//Test').value('(Test/@rslt)[1]', 'VARCHAR(3)');
	
	MERGE Test T
	USING (SELECT @Rqid AS Rqid, @RqroRwno AS RqroRwno, @FileNo AS FileNo) S
	ON (T.Rqro_Rqst_Rqid = S.Rqid     AND
	    T.Rqro_Rwno      = S.RqroRwno AND
	    T.Figh_File_No   = S.FileNo   AND
	    T.Rect_Code      = '001')
	 WHEN MATCHED THEN
	   UPDATE 
	      SET Ctgy_Mtod_Code = @MtodCode
	         ,Ctgy_Code      = @CtgyCode
	         ,Glob_Code      = @GlobCode
	         ,Crtf_Date      = @CrtfDate
	         ,Crtf_Numb      = @CrtfNumb
	         ,Test_Date      = @TestDate
	         ,Rslt           = @Rslt
	 WHEN NOT MATCHED THEN
	   INSERT (Rqro_Rqst_Rqid, Rqro_Rwno, Figh_File_No, Rect_Code, Ctgy_Mtod_Code, Ctgy_Code, Glob_Code, Crtf_Date, Crtf_Numb, Test_Date, Rslt)
	   VALUES (@Rqid, @RqroRwno, @FileNo, '001', @MtodCode, @CtgyCode, @GlobCode, @CrtfDate, @CrtfNumb, @TestDate, @Rslt);
   

    DECLARE @PrvnCode VARCHAR(3)
           ,@RegnCode VARCHAR(3)
           ,@RqtpCode VARCHAR(3)
           ,@RqttCode VARCHAR(3);
    SELECT
      @PrvnCode = REGN_PRVN_CODE
     ,@RegnCode = REGN_CODE
     ,@RqtpCode = RQTP_CODE
     ,@RqttCode = RQTT_CODE
    FROM Request
    WHERE RQID = @Rqid;
    -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
    IF EXISTS(
      SELECT *
        FROM dbo.VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, @MtodCode, @CtgyCode)
    )
      UPDATE Request
         SET SEND_EXPN = '002'
       WHERE RQID = @Rqid;   	   
    ELSE
      UPDATE Request
         SET SEND_EXPN = '001'
       WHERE RQID = @Rqid;   	   
END
GO
