package com.fulldome.mahabharata.model.visual.animation;

public class Anim {
	private int start;
	private int end;
	private int type;

	public int getStart() {
		return start;
	}

	public int getEnd() {
		return end;
	}

	public AnimType getType() {
		return AnimType.values()[type];
	}

	public boolean isPoint() {
		return start == end;
	}
}
