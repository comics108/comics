package com.fulldome.mahabharata.utils;

import java.util.HashMap;
import java.util.Map;

public class YoutubeLinksContainer {
    private Map<Integer, String> dict = new HashMap<Integer, String>();

    public YoutubeLinksContainer() {
        dict.put(1, "https://www.youtube.com/watch?v=U_NGGTWwlCA");
        dict.put(2, "https://www.youtube.com/watch?v=_-ygbi8M5GA");
        dict.put(3, "https://www.youtube.com/watch?v=JQx9Vol63tg");
        dict.put(4, "https://www.youtube.com/watch?v=herOHgAHB4Q");
        dict.put(5, "https://www.youtube.com/watch?v=y4ABjmFenCY");
        dict.put(6, "https://www.youtube.com/watch?v=UHowQ6oMHtY");
        dict.put(7, "https://www.youtube.com/watch?v=mCSEg_EqGy8");
        dict.put(8, "https://www.youtube.com/watch?v=pi-mWY8pF4E");
        dict.put(9, "https://www.youtube.com/watch?v=eJQm4HYlESM");
        dict.put(10, "https://www.youtube.com/watch?v=zxi8palW32A");
        dict.put(11, "https://www.youtube.com/watch?v=rixnDjfq4F0");
        dict.put(12, "https://www.youtube.com/watch?v=M_58XOrSoUY");
        dict.put(13, "https://www.youtube.com/watch?v=E2MldAgz7e0");
        dict.put(14, "https://www.youtube.com/watch?v=pCOAsxsNLhM");
        dict.put(15, "https://www.youtube.com/watch?v=vQf6hEi_-rc");
        dict.put(35, "https://www.youtube.com/watch?v=Luj2ECwBbfI");
        dict.put(36, "https://www.youtube.com/watch?v=dHjlhk8EXIE");
        dict.put(38, "https://www.youtube.com/watch?v=xwLaHx-84iI");
        dict.put(39, "https://www.youtube.com/watch?v=tXAKkd43d94");
        dict.put(37, "https://www.youtube.com/watch?v=XpMhzbCCIqw");
    }

    public Boolean exists(Integer episodeId) {
        return dict.containsKey(episodeId);
    }

    public String link(Integer episodeId) {
        return dict.get(episodeId);
    }
}