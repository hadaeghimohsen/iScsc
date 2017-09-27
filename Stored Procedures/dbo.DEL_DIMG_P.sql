SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_DIMG_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>115</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 115 سطوح امینتی : شما مجوز حذف تصویر مدرک را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   
	DECLARE @Rcid BIGINT
	       ,@Rwno SMALLINT;
	
	SELECT @Rcid = @X.query('//Image_Document').value('(Image_Document/@rcid)[1]', 'BIGINT')
	      ,@Rwno = @X.query('//Image_Document').value('(Image_Document/@rwno)[1]', 'SMALLINT');
	
	UPDATE Image_Document
	   SET IMAG = NULL
	      ,FILE_NAME = NULL
	 WHERE RCDC_RCID = @Rcid
	   AND RWNO = @Rwno;	    
END
GO
