package com.fulldome.mahabharata.model;

import android.content.Context;

import com.fulldome.mahabharata.utils.ComicsUtils;

import java.util.ArrayList;

public class Season {

	private int id;
	private int order;
	private String name;
	private String image;
	private String product;
	private ArrayList<Episode> episodes;
	private SeasonState state = new SeasonState();

	public int getId() {
		return id;
	}

	public int getOrder() {
		return order;
	}

	public String getName() {
		return name.replace("\\n", System.getProperty("line.separator"));
	}

	public String getImage() {
		return ComicsUtils.getImage(image);
	}

	public String getProduct() {
		return product;
	}

	public String getBookName() {
		return  bookInfoParts()[0];
	}

	public String getBookNumber() {
		return bookInfoParts()[1];
	}

	public ArrayList<Episode> getEpisodes() {
		return episodes;
	}

	public Episode getEpisode(int id) {
		for (Episode episode : getEpisodes()) {
			if (episode.getId() == id)
				return episode;
		}
		return null;
	}

	public void delete(Context context) {
		for (Episode episode : getEpisodes())
			episode.delete(context);
	}

	public boolean isPurchased() {
		return state.isPurchased();
	}

	public void setPurchased(boolean purchased) {
		state.setPurchased(purchased);
	}

	public String getPrice() {
		return state.getPrice();
	}

	public void setPrice(String price) {
		state.setPrice(price);
	}

	public boolean isAvailable() {
		return isPurchased() || Settings.getInstance().isSubscribed();
	}

	private String[] bookInfoParts() {
		String[] empty = { "", "" };
		try {
			String[] parts = name.split("\\\\n");
			if (parts.length == 2) {
				return parts;
			} else {
				return empty;
			}
		} catch (Error e) {
			return empty;
		}
	}
}
