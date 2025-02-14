#include <amxmodx>
#include <fakemeta>

#define PREFIX_OLD1 "[LG*|]"
#define PREFIX_OLD2 "[TZG*|]"
#define PREFIX_NEW "[ZoD *|]"
#define COLOR_GREEN "^3"

// This will hook the chat messages
public plugin_init()
{
    register_forward(FM_PlayerPreThink, "on_player_prethink"); // Use FM_PlayerPreThink for more control over client data
}

public on_player_prethink(id)
{
    // Let's check if the message is one that we need to modify.
    new message[192];
    get_user_message(id, message, sizeof(message)); // Get the message sent by the server

    // Check if the message contains the old prefixes
    if (strfind(message, PREFIX_OLD1) != -1 || strfind(message, PREFIX_OLD2) != -1)
    {
        // Replace the old prefix with the new one
        strreplace(message, PREFIX_OLD1, PREFIX_NEW);
        strreplace(message, PREFIX_OLD2, PREFIX_NEW);

        // Add the green color to the new prefix
        new colored_message[192];
        format(colored_message, sizeof(colored_message), "%s%s", COLOR_GREEN, message);

        // Send the modified message to the chat
        client_print(id, print_chat, colored_message);
    }

    return PLUGIN_HANDLED;
}
