SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TEST_SAVE_P]
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
	       
	SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT'),
	       @RqroRwno = @X.query('//Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT'),	       
	       @Rslt     = @X.query('//Test').value('(Test/@rslt)[1]', 'VARCHAR(3)'),
	       @CrtfNumb = @X.query('//Test').value('(Test/@crtfnumb)[1]', 'VARCHAR(20)'),
	       @CrtfDate = @X.query('//Test').value('(Test/@crtfdate)[1]', 'DATE'),
	       @GlobCode = @X.query('//Test').value('(Test/@globcode)[1]', 'VARCHAR(20)');
	       
	SELECT 
	       @RqroRwno = CASE WHEN @RqroRwno IS NULL OR @RqroRwno = 0 THEN 1 ELSE @RqroRwno END
	      ,@FileNo   = FIGH_FILE_NO
	      ,@MtodCode = CTGY_MTOD_CODE
	      ,@CtgyCode = CTGY_CODE
	      ,@GlobCode = CASE WHEN @GlobCode IS NULL THEN GLOB_CODE ELSE @GlobCode END
	      ,@CrtfDate = CASE WHEN @CrtfDate IS NULL THEN CRTF_DATE ELSE @CrtfDate END
	      ,@CrtfNumb = CASE WHEN @CrtfNumb IS NULL THEN CRTF_NUMB ELSE @CrtfNumb END
	      ,@TestDate = TEST_DATE
	      ,@Rslt     = CASE WHEN @Rslt IS NULL OR @Rslt = '004' THEN RSLT ELSE @Rslt END
	FROM Test
	WHERE RQRO_RQST_RQID = @Rqid
	  AND RQRO_RWNO = (CASE WHEN @RqroRwno IS NULL OR @RqroRwno = 0 THEN 1 ELSE @RqroRwno END);
	
	MERGE Test T
	USING (SELECT @Rqid AS Rqid, @RqroRwno AS RqroRwno, @FileNo AS FileNo) S
	ON (T.Rqro_Rqst_Rqid = S.Rqid     AND
	    T.Rqro_Rwno      = S.RqroRwno AND
	    T.Figh_File_No   = S.FileNo   AND
	    T.Rect_Code      = '004')
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
	   VALUES (@Rqid, @RqroRwno, @FileNo, '004' , @MtodCode, @CtgyCode, @GlobCode, @CrtfDate, @CrtfNumb, @TestDate, @Rslt);
END
GO
