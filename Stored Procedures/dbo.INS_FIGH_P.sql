SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_FIGH_P]
	-- Add the parameters for the stored procedure here
	@Rqst_Rqid BIGINT,
	@Prvn_Code VARCHAR(3),
	@Regn_Code VARCHAR(3),
	@File_No   BIGINT OUT
AS
BEGIN   
   
	INSERT INTO Fighter (RQST_RQID, REGN_PRVN_CODE, REGN_CODE)
	VALUES (@Rqst_Rqid, @Prvn_Code, @Regn_Code);
	
	SELECT @File_No = File_No
	FROM Fighter
	WHERE RQST_RQID = @Rqst_Rqid;	
END
GO
