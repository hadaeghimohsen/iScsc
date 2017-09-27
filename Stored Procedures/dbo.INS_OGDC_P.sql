SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_OGDC_P]
	-- Add the parameters for the stored procedure here
	@Sunt_Bunt_Dept_Orgn_Code VARCHAR(2)
  ,@Sunt_Bunt_Dept_Code VARCHAR(2)
  ,@Sunt_Bunt_Code VARCHAR(2)
  ,@Sunt_Code VARCHAR(4)
  ,@Rqdc_Rdid BIGINT
  ,@Need_Type VARCHAR(3)
  ,@Stat VARCHAR(3)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>207</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 207 طوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   	
	INSERT INTO dbo.Organ_Document
	        ( SUNT_BUNT_DEPT_ORGN_CODE ,
	          SUNT_BUNT_DEPT_CODE ,
	          SUNT_BUNT_CODE ,
	          SUNT_CODE ,
	          RQDC_RDID ,
	          ODID ,
	          NEED_TYPE ,
	          STAT 
	        )
	VALUES  ( @SUNT_BUNT_DEPT_ORGN_CODE ,
	          @SUNT_BUNT_DEPT_CODE ,
	          @SUNT_BUNT_CODE ,
	          @SUNT_CODE ,
	          @RQDC_RDID ,
	          0 ,
	          @NEED_TYPE ,
	          @STAT 
	        );
END
GO
