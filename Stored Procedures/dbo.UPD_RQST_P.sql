SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_RQST_P]
	-- Add the parameters for the stored procedure here
	@Rqid BIGINT,
	@Prvn_Code VARCHAR(3),
	@Regn_Code VARCHAR(3),
	@Rqtp_Code VARCHAR(3),
	@Rqtt_Code VARCHAR(3),
	@Lett_No   VARCHAR(15),
	@Lett_Date DATE,
	@Lett_Ownr NVARCHAR(250)
AS
BEGIN
	UPDATE Request
	   SET RQTT_CODE = @Rqtt_Code
	      ,REGN_CODE = @Regn_Code
	      ,REGN_PRVN_CODE = @Prvn_Code
	      ,LETT_NO = @Lett_No
	      ,LETT_DATE = @Lett_Date
	      ,LETT_OWNR = @Lett_Ownr
	 WHERE RQID = @Rqid
	 AND (
	   RQTT_CODE <> @Rqtt_Code OR
	   REGN_CODE <> @Regn_Code OR
	   REGN_PRVN_CODE <> @Prvn_Code OR
	   ISNULL(LETT_NO, 0) <> ISNULL(@Lett_No, 0) OR
	   ISNULL(LETT_DATE, GETDATE()) <> ISNULL(@Lett_Date, GETDATE()) OR
	   ISNULL(LETT_OWNR, 0) <> ISNULL(@Lett_Ownr, 0)
	 )
END
GO
