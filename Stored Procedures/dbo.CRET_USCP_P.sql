SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_USCP_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$CRET_USCP_P]
   
   -- Local Params
   DECLARE @UserId BIGINT;
   SELECT @UserId = @X.query('//User').value('(User/@id)[1]', 'BIGINT')
   
   -- Local Vars
   DECLARE @SchmCode BIGINT,
           @SchmBy VARCHAR(250),
           @SchmName NVARCHAR(100);
   
   -- Run statements
   SELECT @SchmBy = USER_DB, @SchmName = [USER_NAME] FROM dbo.V#Users WHERE ID = @UserId;
   
   -- Check exists valid record
   SELECT @SchmCode = sp.CODE FROM dbo.Schema_Profile sp WHERE sp.SCHM_BY = @SchmBy;
   
   -- Check new sound domain for main profile
   INSERT INTO dbo.Sound ( SCHM_CODE , CODE , SOND_TYPE , STAT )
   SELECT sp.CODE, dbo.GNRT_NVID_U(), ds.VALU, '002'   
     FROM dbo.Schema_Profile sp, dbo.[D$SOND] ds
    WHERE sp.DFLT_STAT = '002'
    AND ds.VALU NOT IN (
        SELECT s.SOND_TYPE
          FROM dbo.Sound s
         WHERE s.SCHM_CODE = sp.CODE
    );
   
   -- IF NOT EXISTS
   IF ISNULL(@SchmCode, 0) = 0 
   BEGIN
      SET @SchmCode = dbo.GNRT_NVID_U();
      INSERT INTO dbo.Schema_Profile ( CODE ,SCHM_NAME ,DFLT_STAT ,SCHM_BY )
      VALUES  ( @SchmCode , N'' , '001' , @SchmBy );
      
      INSERT INTO dbo.Sound ( SCHM_CODE ,CODE ,SOND_TYPE ,SOND_PATH ,STAT )
      SELECT @SchmCode, dbo.GNRT_NVID_U(), s.SOND_TYPE, s.SOND_PATH, s.STAT
        FROM dbo.Schema_Profile sp, dbo.Sound s
       WHERE sp.CODE = s.SCHM_CODE
         AND sp.SCHM_BY = 'ARTAUSER';      
   END;
   	
	COMMIT TRAN [T$CRET_USCP_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$CRET_USCP_P]
	END CATCH
END
GO
