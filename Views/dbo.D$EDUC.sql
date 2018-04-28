SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[D$EDUC] AS SELECT VALU, DOMN_DESC FROM APP_DOMAIN a, iProject.DataGuard.[User] u WHERE A.REGN_LANG = ISNULL(U.REGN_LANG, '054') AND UPPER(u.USERDB) = UPPER(SUSER_NAME()) AND CODE = 'D EDUC'
GO
