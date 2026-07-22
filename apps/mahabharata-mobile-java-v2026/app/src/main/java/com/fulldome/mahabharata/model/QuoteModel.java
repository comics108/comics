package com.fulldome.mahabharata.model;

import com.fulldome.mahabharata.utils.ComicsUtils;

public class QuoteModel {
	private int id;
	private String name;
	private String image;
	private int order;

	public int getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getImage() {
		return ComicsUtils.getImage(image);
	}

	public int getOrder() {
		return order;
	}
}
