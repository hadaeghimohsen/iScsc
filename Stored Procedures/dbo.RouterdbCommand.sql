SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RouterdbCommand]
	-- Add the parameters for the stored procedure here
	/*
	   <Router_Command subsys="5" cmndcode="1" cmnddesc="خواندن اطلاعات مشتریان با شماره کدملی و موبایل">
	      <Fighter fileno="13971010125456564" cellphon="09033927103"/>	      
	   </Router_Command>
	*/
	@X XML,
	@xRet XML OUTPUT
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN ROTR_DBCM_T05
	DECLARE @SubSys INT
	       ,@CmndCode VARCHAR(10)
	       ,@CmndDesc NVARCHAR(100)
	       ,@ExecAsLogin VARCHAR(100)
	       ,@CrntLogin VARCHAR(100) = SUSER_NAME();
   
   SELECT @SubSys = @X.query('Router_Command').value('(Router_Command/@subsys)[1]', 'INT')
         ,@CmndCode = @X.query('Router_Command').value('(Router_Command/@cmndcode)[1]', 'VARCHAR(10)')
         ,@ExecAsLogin = @X.query('Router_Command').value('(Router_Command/@execaslogin)[1]', 'VARCHAR(100)');
   
   IF @SubSys = 0
   BEGIN
      EXEC iProject.dbo.RouterdbCommand @X = @X, @xRet = @xRet OUTPUT -- xml      
   END 
   ELSE IF @SubSys = '5' 
   BEGIN
      EXEC AS LOGIN = ISNULL(@ExecAsLogin, @CrntLogin);
      EXEC iScsc.dbo.RunnerdbCommand @X = @X, @xRet = @xRet OUTPUT -- xml
      EXEC AS LOGIN = @CrntLogin;
   END
   ELSE IF @SubSys = '11' AND EXISTS (SELECT name FROM sys.databases WHERE name = N'iCRM')
   BEGIN
      EXEC iCRM.dbo.RouterdbCommand @X = @X, @xRet = @xRet OUTPUT -- xml      
   END 
   ELSE IF @SubSys = '12' AND EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
   BEGIN
      EXEC iRoboTech.dbo.RouterdbCommand @X = @X, @xRet = @xRet OUTPUT -- xml      
   END 
   
   COMMIT TRAN ROTR_DBCM_T05;
   RETURN 1;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      --RAISERROR ( @ErrorMessage, -- Message text.
      --         16, -- Severity.
      --         1 -- State.
      --         );
      SELECT 0 AS CODE, @ErrorMessage AS MESG;
      ROLLBACK TRAN ROTR_DBCM_T05;
   END CATCH
END
GO
