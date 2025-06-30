/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int gappih    = 5;       /* horiz inner gap between windows */
static const unsigned int gappiv    = 5;       /* vert inner gap between windows */
static const unsigned int gappoh    = 5;       /* horiz outer gap between windows and screen edge */
static const unsigned int gappov    = 5;       /* vert outer gap between windows and screen edge */
static       int smartgaps          = 0;        /* 1 means no outer gap when there is only one window */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 1;    /* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;        /* 0 means no systray */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "IosevkaTerm Nerd Font Mono:size=10" };
static const char dmenufont[]       = "IosevkaTerm Nerd Font Mono:size=10";
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#161616";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

static const char *const autostart[] = {
	"xfce4-clipman", NULL,
	"xfce4-power-manager", NULL,
	"xfce4-screensaver", NULL,
	"nm-applet", NULL,
	"slstatus", NULL,
	"bash", "-c", "/home/mm-2103/.config/suckless/dwm/autostart.sh", NULL,
	NULL /* terminate */
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class		 instance    title       tags mask     isfloating   monitor */
	{ "thunderbird",	  NULL,       NULL,       1 << 8,       0,           -1 },
	{ "discord",		  NULL,       NULL,       1 << 7,       0,           -1 },
	{ "Antares",		  NULL,       NULL,       1 << 6,       0,           -1 },
	{ "pavucontrol",	  NULL,       NULL,       1 << 5,       0,           -1 },
	{ "YouTube Music",	  NULL,       NULL,       1 << 4,       0,           -1 },
	{ "bruno",		  NULL,       NULL,       1 << 3,       0,           -1 },

};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "[M]",      monocle },
	{ "[@]",      spiral },
	{ "[\\]",     dwindle },
	{ "H[]",      deck },
	{ "TTT",      bstack },
	{ "===",      bstackhoriz },
	{ "HHH",      grid },
	{ "###",      nrowgrid },
	{ "---",      horizgrid },
	{ ":::",      gaplessgrid },
	{ "|M|",      centeredmaster },
	{ ">M>",      centeredfloatingmaster },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/bash", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "rofi", "-show", "drun", "-font", dmenufont, NULL };
static const char *termcmd[]  = { "kitty", NULL };
static const char *closecmd[] = { "kill -HUP dwm", NULL };
static const char *browsercmd[] = { "zen-browser", NULL };
static const char *lockcmd[] = { "betterlockscreen", "-l", NULL };
static const char *suspendcmd[] = { "systemctl", "suspend", NULL };
static const char *screenshotcmd[] = { "flameshot", "gui", NULL };
static const char *playercmd[] = { "playerctl", "play-pause", NULL };
static const char *upvolcmd[] = {"vol-notif.sh", "--increase", "5", NULL};
static const char *downvolcmd[] = {"vol-notif.sh", "--decrease", "5", NULL};
static const char *mutevolcmd[] = {"vol-notif.sh", "--toggle-mute", NULL};
static const char *brightnessupcmd[] = {"brightnessctl", "set", "+10%", NULL};


#include <X11/XF86keysym.h>

static const Key keys[] = {
	/* modifier                     key				   function        argument */
	{ MODKEY,                       XK_p,				   spawn,          {.v = dmenucmd } },
	{ MODKEY,			XK_Return,			   spawn,          {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_b,				   togglebar,      {0} },
	{ MODKEY,                       XK_j,				   focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,				   focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,				   incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,				   incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,				   setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,				   setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_h,				   setcfact,       {.f = +0.25} },
	{ MODKEY|ShiftMask,             XK_l,				   setcfact,       {.f = -0.25} },
	{ MODKEY|ShiftMask,             XK_o,				   setcfact,       {.f =  0.00} },
	{ MODKEY|ShiftMask,             XK_Return,			   zoom,           {0} },
	{ MODKEY,                       XK_Tab,				   view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,				   killclient,     {0} },
	{ MODKEY,                       XK_t,				   setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,				   setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,				   setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,			   setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,			   togglefloating, {0} },
	{ MODKEY,                       XK_0,				   view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,				   tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,			   focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period,			   focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,			   tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,			   tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,						   0)
	TAGKEYS(                        XK_2,						   1)
	TAGKEYS(                        XK_3,						   2)
	TAGKEYS(                        XK_4,						   3)
	TAGKEYS(                        XK_5,						   4)
	TAGKEYS(                        XK_6,						   5)
	TAGKEYS(                        XK_7,						   6)
	TAGKEYS(                        XK_8,						   7)
	TAGKEYS(                        XK_9,						   8)
	{ MODKEY|ControlMask|ShiftMask, XK_q,				   quit,           {.v = closecmd } },
	{ MODKEY,			XK_b,				   spawn,	   {.v = browsercmd } },
	{ MODKEY|ShiftMask,		XK_x,				   spawn,	   {.v = lockcmd } },
	{ MODKEY|ShiftMask,		XK_s,				   spawn,	   {.v = suspendcmd } },
	{0,				XK_Print,			   spawn,	   {.v = screenshotcmd } },
	{0,				XK_Pause,			   spawn,	   {.v = playercmd } },
	{0,				XF86XK_AudioRaiseVolume,	   spawn,	   {.v = upvolcmd   } },
	{0,			        XF86XK_AudioLowerVolume,	   spawn,	   {.v = downvolcmd } },
	{0,				XF86XK_AudioMute,		   spawn,	   {.v = mutevolcmd } },
	{0,				XF86XK_MonBrightnessUp,		   spawn,	   {.v = brightnessupcmd } },


};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

