#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <crxranks>
#include <zombieplague>

#define PLUGIN_VERSION "1.0"

new Trie:g_tAP

public plugin_init()
{
    register_plugin("CRXRanks: ZP Per Level", PLUGIN_VERSION, "OciXCrom")
    register_cvar("CRXRanksAPPL", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
}

public plugin_cfg()
{
    g_tAP = TrieCreate()
    ReadFile()
}

public plugin_end()
{
    TrieDestroy(g_tAP)
}

ReadFile()
{
    new szConfigsName[256], szFilename[256]
    get_configsdir(szConfigsName, charsmax(szConfigsName))
    formatex(szFilename, charsmax(szFilename), "%s/RankSystemAmmoPacks.ini", szConfigsName)

    new iFilePointer = fopen(szFilename, "rt")

    if(iFilePointer)
    {
        new szData[64], szValue[32], szMap[32], szKey[32], bool:bRead = true, iSize
        get_mapname(szMap, charsmax(szMap))

        while(!feof(iFilePointer))
        {
            fgets(iFilePointer, szData, charsmax(szData))
            trim(szData)

            switch(szData[0])
            {
                case EOS, '#', ';': continue
                case '-':
                {
                    iSize = strlen(szData)

                    if(szData[iSize - 1] == '-')
                    {
                        szData[0] = ' '
                        szData[iSize - 1] = ' '
                        trim(szData)

                        if(contain(szData, "*") != -1)
                        {
                            strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '*')
                            copy(szValue, strlen(szKey), szMap)
                            bRead = equal(szValue, szKey) ? true : false
                        }
                        else
                        {
                            static const szAll[] = "#all"
                            bRead = equal(szData, szAll) || equali(szData, szMap)
                        }
                    }
                    else continue
                }
                default:
                {
                    if(!bRead)
                        continue

                    strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                    trim(szKey); trim(szValue)

                    if(!szValue[0])
                        continue

                    TrieSetCell(g_tAP, szKey, str_to_num(szValue))
                }
            }
        }

        fclose(iFilePointer)
    }
}

public crxranks_user_level_updated(id, iLevel, bool:bLevelUp)
{
    if(!bLevelUp)
        return

    new szLevel[10]
    num_to_str(iLevel, szLevel, charsmax(szLevel))

    if(TrieKeyExists(g_tAP, szLevel))
    {
        new iAP
        TrieGetCell(g_tAP, szLevel, iAP)
        zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + iAP)
        CC_SendMessage(id, "&x04* &x01You received &x04%i AmmoPacks &x01for reaching level &x03%i&x01.", iAP, iLevel)
    }
} 