SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_RQRO_P]
	-- Add the parameters for the stored procedure here
	@RQST_RQID BIGINT,
	@RWNO SMALLINT
AS
BEGIN
	IF NOT EXISTS(
	   SELECT * 
	     FROM Request
	    WHERE RQID = @RQST_RQID
	      AND SSTT_MSTT_CODE = 1
	      AND SSTT_CODE = 1
	)
	BEGIN
	   RAISERROR(N'درخواست هایی که از وضعیت ثبت موقت درخواست خارج شده اند دیگر قادر به پاک شدن نیستند', 16, 1);
	END
	
	DECLARE @RqtpCode VARCHAR(3);
	SELECT @RqtpCode = RQTP_CODE
	  FROM Request
	 WHERE RQID = @RQST_RQID;
   
   IF @RqtpCode = '002'
      DELETE Fighter_Public WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '003'
      DELETE Calculate_Calorie WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '004'
      DELETE Heart_Zone WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '005'
      DELETE Physical_Fitness WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '006'
      DELETE Test WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '007'
      DELETE Exam WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '008'
      DELETE Campitition WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '009' OR @RqtpCode = '010'
      DELETE Member_Ship WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   ELSE IF @RqtpCode = '011'
   BEGIN
      DELETE Fighter_Public WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
      DELETE Test WHERE RQRO_RQST_RQID = @RQST_RQID AND RQRO_RWNO = @RWNO;
   END
   DELETE Request_Row
    WHERE RQST_RQID = @RQST_RQID
      AND RWNO = @RWNO;
	
END
GO
