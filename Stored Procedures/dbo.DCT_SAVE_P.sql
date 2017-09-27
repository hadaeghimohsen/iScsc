SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DCT_SAVE_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>114</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 114 سطوح امینتی : شما مجوز درج و ویرایش اطلاعات و تصویر مدرک را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   -- پایان دسترسی   
	DECLARE @Rcid BIGINT
	       ,@DelvDate DATE
	       ,@RcdcStat VARCHAR(3)
	       ,@PermStat VARCHAR(3)
	       ,@StrtDate DATE
	       ,@EndDate  DATE
	       ,@RcdcDesc NVARCHAR(250)
	       ,@Imag     VARCHAR(MAX)
	       ,@FileName NVARCHAR(500);
	
	DECLARE C$SAVERCDC CURSOR FOR
	   SELECT r.query('.').value('(Receive_Document/@rcid)[1]', 'BIGINT')
	         ,r.query('.').value('(Receive_Document/@delvdate)[1]', 'DATE')
	         ,r.query('.').value('(Receive_Document/@rcdcstat)[1]', 'VARCHAR(3)')
	         ,r.query('.').value('(Receive_Document/@permstat)[1]', 'VARCHAR(3)')
	         ,r.query('.').value('(Receive_Document/@strtdate)[1]', 'DATE')
	         ,r.query('.').value('(Receive_Document/@enddate)[1]', 'DATE')
	         ,r.query('.').value('(Receive_Document/@rcdcdesc)[1]', 'NVARCHAR(250)')
	         ,r.query('Image_Document').value('(Image_Document/@filename)[1]', 'NVARCHAR(500)')
	         ,r.query('Image_Document').value('.', 'VARCHAR(MAX)')
	     FROM @X.nodes('//Receive_Document') Rcdc(r);
	
	OPEN C$SAVERCDC;
	NEXTC$SAVERCDC:
	FETCH NEXT FROM C$SAVERCDC INTO @Rcid, @DelvDate, @RcdcStat, @PermStat, @StrtDate, @EndDate, @RcdcDesc, @FileName, @Imag;
	
	IF @@FETCH_STATUS <> 0
	   GOTO ENDC$SAVERCDC;
	
	/*IF @Imag IS NOT NULL 
	BEGIN
	   --IF @RcdcStat IS NULL
	   SET @RcdcStat = '002';
	   --IF @PermStat IS NULL
	   SET @PermStat = '002';
	END*/
	
	UPDATE Receive_Document
	   SET DELV_DATE = @DelvDate
	      ,RCDC_STAT = @RcdcStat
	      ,PERM_STAT = @PermStat
	      ,STRT_DATE = @StrtDate
	      ,END_DATE  = @EndDate
	      ,RCDC_DESC = @RcdcDesc
	 WHERE RCID = @Rcid;
	
	UPDATE Image_Document
	   SET IMAG      = @Imag
	 WHERE RCDC_RCID = @Rcid
	   AND RWNO      = 1;
	   
	GOTO NEXTC$SAVERCDC;
	ENDC$SAVERCDC:
	CLOSE C$SAVERCDC;
	DEALLOCATE C$SAVERCDC;    
	 
	   
END
GO
